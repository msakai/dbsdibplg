{
    Dibas Plug-in for "Dib Retouch Plug-in" version 0.12
    Copyright (C) 1999  Masahiro Sakai <ZVM01052@nifty.ne.jp>
}

{
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}

unit unit1;

interface

uses
{$IFDEF WIN32}
  Windows,
{$ELSE}
  WinTypes, WinProcs,
{$ENDIF}
  SysUtils, Classes, Forms, Controls, StdCtrls, Buttons, ComCtrls, PlugIf;

type
  TDialog1 = class(TForm)
    TreeView1: TTreeView;
    AboutBtn: TBitBtn;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    PreviewBtn: TBitBtn;
    procedure PreviewBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure FormShow(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
  private
    FPreviewed: Boolean;   { "Preview"が一度でも呼ばれたか }
    FModified: Boolean;    { 最後の"Preview"が呼ばれた後にパラメータ変更がなされたか。 }
    FCanPreview: Boolean;
  protected
    procedure DoShow; override;
    procedure SetCanPreview(Value: Boolean); virtual;
  public
    procedure Preview; dynamic;
    procedure Modified; dynamic;
    { パラメータに変更があったときこのメソッドを呼ばなくてはなりません }
    property CanPreview: Boolean read FCanPreview write SetCanPreview;
    { プレビューが可能か？ }
  end;

type
  TGetPluginInfo = function(nInfoNo: Integer; lpBuf: PChar;
     nBufLen: Integer): Integer; stdcall;

  TRetouch = function(nFlag: Integer;
    var hSrcInfo, hSrcBits, hDstInfo, hDstBits: THandle;
    lpCB: TFarProc; lData: Longint): Integer; stdcall;


  TDibRetouchPlugin = class(TObject)
  private
      FHandle: THandle;
      FFunctionNames: TStrings;
      FInfo, FGroup: string;
  public
      constructor Create(h: THandle);
      destructor Destroy; override;
      function Retouch(No: Word; nFlag: Integer;
        var hSrcInfo, hSrcBits, hDstInfo, hDstBits: THandle;
        lpCB: TFarProc; lData: Longint): Integer;
      function Filter(No: Word; var Arg: TFilterArg): Integer;
      property FunctionNames: TStrings read FFunctionNames;
      property Group: string read FGroup;
      property Info: string read FInfo;
  end;


{ Exported functions }

{$IFDEF WIN32}
  procedure PlugInfo(var Info: TPlugInfo); stdcall;
  procedure FilterInfo(No: Word; var Info: TFilterInfo); stdcall;
  function  SetParam(No: Word; ParentWindow: hwnd; Pen: WordBool): Integer; stdcall;
  function  Filter(No: Word; var Arg: TFilterArg)     : Integer; stdcall;
  function  Resize(No: Word; var Arg: TResizeArg)     : Integer; stdcall;
  function  Combine(No: Word; var Arg: TCombineArg)   : Integer; stdcall;
  function  Quantize(No: Word; var Arg: TQuantizeArg) : Integer; stdcall;
{$ELSE}
  procedure PlugInfo(var Info: TPlugInfo); export;
  procedure FilterInfo(No: Word; var Info: TFilterInfo); export;
  function  SetParam(No: Word; ParentWindow: hwnd; Pen: WordBool): Integer; export;
  function  Filter(No: Word; var Arg: TFilterArg)     : Integer; export;
  function  Resize(No: Word; var Arg: TResizeArg)     : Integer; export;
  function  Combine(No: Word; var Arg: TCombineArg)   : Integer; export;
  function  Quantize(No: Word; var Arg: TQuantizeArg) : Integer; export;
{$ENDIF}

resourcestring
    SCancel  = 'キャンセル';
    SPreview = 'プレビュー';
    SNoItemSelected = '有効な項目が選択されていません';
    
implementation

{$R *.DFM}
{$R strres.res}

var
  PluginList: TList;
  SelPlugin: TDibRetouchPlugin = nil;
  SelFilterID: Integer = 0;


{ Utility functions }

function CopyFont(Src: HFONT): HFONT;
var LogFont: TLogFont;
begin
    GetObject(Src, SizeOf(LogFont), @LogFont);
    Result := CreateFontIndirect(LogFont);
end;

function AddOffset(p: Pointer; Offset: LongInt): Pointer;
begin
    Result := Pointer(LongInt(p) + Offset);
end;

{ Initialization & Finalization function }

procedure SearchPlugins;
const
{$IFDEF WIN32}
    PluginExt = 'DPP';
{$ELSE}
    PluginExt = 'DPI';
{$ENDIF}
var SearchRec: TSearchRec;
    Found: Integer;
    PluginPath: string;
    h: THandle;
    p: TGetPluginInfo;
    s: AnsiString;
begin
    PluginPath := ExtractFilePath(Application.ExeName);

    Found := FindFirst(PluginPath + '*.' + PluginExt, 0, SearchRec);
    while Found = 0 do begin
        h := LoadLibrary(PChar(PluginPath + SearchRec.Name));
        if h <> 0 then begin
            p := GetProcAddress(h, PChar(1));
            if Assigned(p) then begin
                SetLength(s, 256);
                SetLength(s, p(0, PChar(s), Length(s)));
                if (s = '0000') and (p(3, nil, 0) > 0) then begin
                    PluginList.Add(TDibRetouchPlugin.Create(h));
                end else FreeLibrary(h);
            end else FreeLibrary(h);
        end;
        Found := FindNext(SearchRec);
    end;
    FindClose(SearchRec);
end;

procedure FreePlugins;
var i: Integer;
begin
    for i := 0 to PluginList.Count - 1 do
        if Assigned(PluginList.Items[i]) then
            TDibRetouchPlugin(PluginList.Items[i]).Free;
end;

{ Exported functions }

procedure PlugInfo;
begin
    with Info do begin
	version  := IFPLUG_VERSION;
        aboutID  := 100;      { プラグインの説明のリソースＩＤ }
        if PluginList.Count <> 0 then begin
            flag     := PLGF_LOCKDLL;
	    nEntries := 1;
        end else begin
            flag     := 0;
            nEntries := 0;
        end;
    end;
end;

procedure FilterInfo;
begin
    if No = 1 then begin
        Info.FilterType := FT_OTHER;
        Info.Flag       := FF_MENUONLY;
        Info.NameID     := 1;
    end;
end;

function SetParam;
var hFont1: THandle;
    Dlg: TDialog1;
begin
    if No <> 1 then begin
        Result := FTR_FAIL;
        Exit;
    end;

    Dlg := TDialog1.CreateParented(ParentWindow);
    try
        hFont1 := SendMessage(ParentWindow, DBSM_GET_TOOLFONT, 0, 0);
        if Pen and (hFont1=0) then
            hFont1 := SendMessage(GetParent(ParentWindow), DBSM_GET_TOOLFONT, 0, 0);

        if hFont1 <> 0 then
            Dlg.Font.Handle := CopyFont(hFont1);

        Dlg.CanPreview  := not Pen;
        Dlg.Caption     := LoadStr(1);

        case Dlg.ShowModal of
          idOK:     Result := FTR_OK;
          idCancel: Result := FTR_CANCEL;
          else      Result := FTR_FAIL;
        end;
    finally
        Dlg.Free;
    end;
end;

function Filter;
begin
    Result := FTR_FAIL;
    if (No = 1) and Assigned(SelPlugin) then begin
        Result := SelPlugin.Filter(SelFilterID, Arg);
    end;
end;

function Resize;
begin
    Result := FTR_FAIL;
end;

function Combine;
begin
    Result := FTR_FAIL;
end;

function Quantize;
begin
    Result := FTR_FAIL;
end;

{ Methods }

procedure TDialog1.DoShow;
begin
    inherited;
    PreviewBtn.Visible := CanPreview;
end;

procedure TDialog1.Preview;
begin
    if CanPreview and FModified then begin
        FPreviewed := True;
        FModified  := False;
        SendMessage(GetParentHandle, DBSM_FILTER_PREVIEW, 0, 0);
    end;
end;

procedure TDialog1.Modified;
begin
    if FPreviewed then
       FModified := True;
end;


procedure TDialog1.SetCanPreview(Value: Boolean);
begin
    FCanPreview := Value;
end;

{ Event Handler }

procedure TDialog1.FormCreate(Sender: TObject);
var i, j: Integer;
    Plugin    : TDibRetouchPlugin;
    GroupNode : TTreeNode;
    GroupList : TStringList;
    GroupID   : Integer;
    Node      : TTreeNode;
begin
    CancelBtn.Caption  := SCancel;
    PreviewBtn.Caption := SPreview;

    GroupList := TStringList.Create;
    try
        for i := 0 to PluginList.Count - 1 do begin
            Plugin  := TDibRetouchPlugin(PluginList.Items[i]);

            if Plugin.Group = '' then begin
                GroupNode := nil
            end else begin
                GroupID := GroupList.IndexOf(Plugin.Group);
                if GroupID = -1 then begin
                    GroupNode := TreeView1.Items.Add(nil, Plugin.Group);
                    GroupList.AddObject(Plugin.Group, GroupNode);
                end else
                    GroupNode := TTreeNode(GroupList.Objects[GroupID]);
            end;

            for j := 0 to Plugin.FunctionNames.Count - 1 do begin
                Node := TreeView1.Items.AddChildObject(GroupNode, Plugin.FunctionNames[j], Plugin);
                Plugin.FunctionNames.Objects[j] := Node;
                if (Plugin = SelPlugin) and (SelFilterID = j) then
                    Node.Selected := True;
            end;
        end;
    finally
        GroupList.Free;
    end;
end;

procedure TDialog1.FormShow(Sender: TObject);
begin
    FModified := True;
end;

procedure TDialog1.OKBtnClick(Sender: TObject);
begin
    if (Treeview1.Selected = nil) or (Treeview1.Selected.Data = nil) then begin
        MessageBox(Handle, PChar(SNoItemSelected), '', MB_OK);
        ModalResult := mrNone;
        Exit;
    end;

    if CanPreview and FPreviewed and FModified then
        Preview;
end;

procedure TDialog1.PreviewBtnClick(Sender: TObject);
begin
    if (Treeview1.Selected = nil) or (Treeview1.Selected.Data = nil) then begin
        MessageBox(Handle, PChar(SNoItemSelected), '', MB_OK);
        Exit;
    end;
    Preview;
end;

procedure TDialog1.AboutBtnClick(Sender: TObject);
begin
    if (TreeView1.Selected <> nil) and (TreeView1.Selected.Data <> nil) then
        MessageBox(Handle, PChar(TDibRetouchPlugin(TreeView1.Selected.Data).Info), 'About plug-in', MB_OK)
    else
        MessageBox(Handle, PChar(SNoItemSelected), '', MB_OK);
end;

procedure TDialog1.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
    if Assigned(Node.Data) then begin
        SelPlugin   := TDibRetouchPlugin(Node.Data);
        SelFilterID := SelPlugin.FunctionNames.IndexOfObject(Node);
    end else begin
        SelPlugin := nil;
    end;
    Modified;
end;

{ TDibRetouchPlugin class }

constructor TDibRetouchPlugin.Create(h: THandle);
var i: Integer;
    p: TGetPluginInfo;
    FunctionNum: Integer;
    function GetInfo(No: Integer): AnsiString;
    begin
        SetLength(Result, 256);
        FillChar(PChar(Result)^, Length(Result), 0);
        p(No, PChar(Result), Length(Result));
        SetLength(Result, StrLen(PChar(Result)));
    end;
begin
    inherited Create;
    FFunctionNames := TStringList.Create;
    FHandle := h;
    p := GetProcAddress(h, PChar(1));

    if not Assigned(p) then
        raise Exception.Create('failed "GetProcAddress"');

    FInfo  := GetInfo(1);
    FGroup := GetInfo(2);
    FunctionNum := p(3, nil, 0);
    for i := 0 to FunctionNum - 1 do
        FFunctionNames.Add(GetInfo(i + 4));
end;

destructor TDibRetouchPlugin.Destroy;
begin
    FFunctionNames := TStringList.Create;
    FreeLibrary(FHandle);
    inherited;
end;

function TDibRetouchPlugin.Retouch(No: Word; nFlag: Integer;
  var hSrcInfo, hSrcBits, hDstInfo, hDstBits: THandle;
  lpCB: TFarProc; lData: Longint): Integer;
var p: TRetouch;
begin
    p := GetProcAddress(FHandle, PChar(No + 2));
    if Assigned(p) then
        Result := p(nFlag, hSrcInfo, hSrcBits, hDstInfo, hDstBits, lpCB, lData)
    else
        Result := -1;
end;

function TDibRetouchPlugin.Filter(No: Word; var Arg: TFilterArg): Integer;
type
    TRGBQuadArray = array[0..255] of TRGBQuad;
    PRGBQuadArray = ^TRGBQuadArray;
var hSrcInfo, hSrcBits, hDstInfo, hDstBits: THandle;
    pInfo: PBitmapInfo;
    pBits: Pointer;
    LineSize: Integer;
    i, j: Integer;
    PIn  : PByte;
    POut : PRGBTriple;
    PColors: PRGBQuadArray;
    IsTopDown: Boolean;
begin
    Result := FTR_FAIL;

    { ヘッダの準備 }
    hSrcInfo := GlobalAlloc(GHND, SizeOf(TBitmapInfo));
    pInfo := GlobalLock(hSrcInfo);
    if pInfo = nil then
        Exit;
    with pInfo^.bmiHeader do begin
        biSize        := SizeOf(TBitmapInfoHeader);
        biWidth       := Arg.cxInData;
        biHeight      := Arg.cyInData;
        biPlanes      := 1;
        biBitCount    := 24;
        biCompression := BI_RGB;
    end;
    GlobalUnLock(hSrcInfo);


    if Arg.AbortFunc(25, 100) <> FTR_OK then begin
        Result := FTR_CANCEL;
        Exit;
    end;

    { Bitデータの準備 }
    LineSize := ((Arg.cxInData * 3 + 3) div 4) * 4;

    hSrcBits := GlobalAlloc(GHND, LineSize * Arg.cyInData);
    pBits    := GlobalLock(hSrcBits);
    if pBits = nil then
        Exit;
    for i := 0 to Arg.cyInData - 1 do
        Move(Arg.inData[i]^, AddOffset(pBits, (Arg.cyInData - 1 - i) * LineSize)^, Arg.cxIndata * 3);
    GlobalUnLock(hSrcBits);

    { 実処理 }
    try
        if Arg.AbortFunc(50, 100) <> FTR_OK then begin
            Result := FTR_CANCEL;
            Exit;
        end;
        if Retouch(No, 0, hSrcInfo, hSrcBits, hDstInfo, hDstBits, nil, 0) <> 0 then
            Exit;
    finally
        GlobalFree(hSrcInfo);
        GlobalFree(hSrcBits);
    end;

    if Arg.AbortFunc(75, 100) <> FTR_OK then begin
        Result := FTR_CANCEL;
        Exit;
    end;

    { 結果のコピー }
    pInfo := GlobalLock(hDstInfo);
    pBits := GlobalLock(hDstBits);
    if (pInfo = nil) or (pBits = nil) then
        Exit;
    try
        with pInfo^.bmiHeader do begin
            if (biWidth < Arg.cxInData) or (Abs(biHeight) < Arg.cyIndata) or (biCompression <> BI_RGB) then
                Exit;
            LineSize  := ((biWidth * (biBitCount div 8) + 3) div 4) * 4;
            IsTopDown := biHeight < 0;
        end;
        PColors := AddOffset(pInfo, pInfo^.bmiHeader.biSize);
        case pInfo^.bmiHeader.biBitCount of
          24:begin
                 if IsTopDown then begin
                     for i := 0 to Arg.cyData - 1 do
                         Move(AddOffset(pBits, (i + Arg.yInData) * LineSize + Arg.xInData * 3)^, Arg.outData[i]^, Arg.cxData * 3);
                 end else begin
                     for i := 0 to Arg.cyData - 1 do
                         Move(AddOffset(pBits, (Arg.cyIndata - 1 - (i + Arg.yInData)) * LineSize + Arg.xInData * 3)^, Arg.outData[i]^, Arg.cxData * 3);
                 end;
             end;
          8: begin
                 for i := 0 to Arg.cyData - 1 do begin
                     if IsTopDown then
                         PIn := PByte(AddOffset(pBits, i + Arg.yInData * LineSize + Arg.xInData))
                     else
                         PIn := PByte(AddOffset(pBits, (Arg.cyIndata - 1 - (i + Arg.yInData)) * LineSize + Arg.xInData));
                     POut := PRGBTriple(Arg.outData[i]);
                     for j := 0 to Arg.cxData - 1 do begin
                         with PColors^[PIn^] do begin
                             POut^.rgbtBlue  := rgbBlue;
                             POut^.rgbtGreen := rgbGreen;
                             POut^.rgbtRed   := rgbRed;
                         end;
                         Inc(PIn);
                         Inc(POut);
                     end;
                 end;
             end;
          else Exit;
        end;
    finally
        GlobalFree(hDstInfo);
        GlobalFree(hDstBits);
    end;

    Arg.Abortfunc(100, 100);
    Result := FTR_OK;
end;



initialization
    PluginList := TList.Create;
    SearchPlugins;
finalization
    FreePlugins;
    PluginList.Free;
end.
