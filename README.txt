readme.txt


Dibas Plug-in for "Dib Retouch Plug-in"
Version 0.12


0. はじめに

    このソフトウェアはDibas32 Ver1.04に七☆星氏と酔伯氏とで仕様の策定をしている
   「DIB画像操作(レタッチ)プラグイン」を扱う機能を提供するDibas32用のプラグイン
    です。対応しているプラグイン仕様のバージョンは「0000」です。


1. 著作権や使用条件等

     本ライブラリはフリー・ソフトウェアです。あなたは、Free Software
     Foundation が公表したGNU ライブラリ一般公有使用許諾の第2版或いはそ
     れ以降の各版のいずれかを選択し、その版が定める条項の許で本ライブラ
     リを再配布または変更することができます。
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

     本ライブラリは有用とは思いますが、配布にあたっては、市場性及び特
     定目的適合性についての暗黙の保証を含めて、いかなる保証も行ないま
     せん。詳細についてはGNU ライブラリ一般公有使用許諾書をお読みください。
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.


2. インストール方法

    "dibplug.f32" と 「DIB画像操作(レタッチ)プラグイン」(*.dpp)をDibas32をイン
    ストールしたディレクトリにコピーして下さい。


3. アンインストール方法

    Dibas32 をインストールしたディレクトリにコピーした dibplug.f32 と 「DIB画像
    操作プラグイン」(*.dpp) を削除して下さい。


4．使い方

    「DIB画像操作プラグイン」(*.dpp)が同じディレクトリに存在する場合は、Dibas32
    の[フィルタ]メニューに[DIBレタッチプラグイン]という項目が追加されているはず
    です。これを選択することで他のフィルタと同様に扱えます。
    (ただし、内部の変換処理があるので速度は多少遅いでしょう。)
    また、利用できるPluginには幾つかの制約があります。これを満たさないプラグイ
    ンを使うとエラーメッセージが表示されますが問題はありません。
    (これらの制限は私の手抜きによるものです。^^;)
　　1. 処理後の画像が、非圧縮の24bitか8bit画像であること。
　　2. 処理後のサイズが処理前より小さくならないこと。


5. 独り言

    書籍などに収録する場合は見本誌等を一部をいただけるとうれしいな～


6. 連絡先

    e-mail: ZVM01052@nifty.ne.jp


7. 更新履歴

    1999年5月3日 v0.10  初公開バージョン
    1999年5月8日 v0.11
      ・グループを持たないプラグインへの配慮
      ・出力が8bitのプラグインに対応
      ・出力がトップダウンDIBのプラグインに対応
      ・プラグインの解放漏れを修正
      ・ヘッダのサイズをちゃんと確認するようにした
      ・細かい修正
    1999年7月24日 v0.12
      ・ライセンスをLGPLに変更
