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


library dibplug;

uses
  unit1 in 'unit1.pas' {Dialog1};

{$R *.RES}

exports
  PlugInfo   name 'PlugInfo',
  SetParam   name 'SetParam',
  FilterInfo name 'FilterInfo',
  Filter     name 'Filter',
  Resize     name 'Resize',
  Combine    name 'Combine',
  Quantize   name 'Quantize';

{$IFDEF WIN32}
  {$E f32}
{$ENDIF}

begin
end.