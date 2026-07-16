# Canon LBP9100C USB 印刷調査 引き継ぎ

最終更新: 2026-07-15

## 現在の状態

作業はユーザー指示により一旦中断した。まだテストページの物理印刷には成功していない。

USB デバイスの検出、`usblp`、udev、CUPS キュー、Canon CAPT デーモン、NixOS 上での 32/64 bit バイナリ実行、Ghostscript から Canon ドライバーを呼ぶところまでは到達している。現在の主な未解決点は、Canon の 32 bit `c3pldrv` 内で `StartJob` が失敗すること。

最新の確定ログは次のとおり。

```text
StartJob context=1
StartDoc context=1
StartJob internal return: -1
errorno=0
opvpErrorNo=0
job_started=0
doc_started=0
page_started=0
failure_pc=0x8051cfe
```

このため、後続の次のログは原因ではなく結果である。

```text
Error Response:ReqNo=5, SeqNo=4,opvpErrorNo=-2
Error Response:ReqNo=7, SeqNo=31,opvpErrorNo=-2
GPL Ghostscript 10.07.1: Unrecoverable error, exit code 1
```

## リポジトリの変更

現在、次の 5 ファイルが Git の index に入っている。

```text
M  nixos/printing.nix
M  non-module/allowUnfreePredicate.nix
A  pkgs/canon-capt.nix
A  pkgs/canon-pstocapt3-resolution.patch
A  pkgs/ghostscript-opvp-string.patch
```

変更内容の要約:

- `pkgs/canon-capt.nix`
  - Canon 公式 CAPT 2.71 を RPM から展開する。
  - 公式アーカイブ:
    `https://gdlp01.c-wss.com/gds/7/0100003447/08/linux-capt-drv-v271-jp.tar.gz`
  - hash: `sha256-X0P3RhIBi1ehZu5vaL81aURt9Lr0cKegLNxRP5aQyj0=`
  - 32/64 bit ELF の interpreter と RPATH を Nix store に合わせる。
  - `/usr/bin/gs` がハードコードされた `pstocapt3` をソースから再ビルドする。
  - modern CUPS 用に PPD の Resolution choice を `600dpi` にする。
  - OPVP ドライバーを絶対 store path に置換する。
- `pkgs/canon-pstocapt3-resolution.patch`
  - PPD choice は `600dpi` のまま、Canon の JobInfo へは元の数値形式 `Resolution=600` を渡す。
  - これは主因ではなかったが、Canon が期待する形式なので残す価値がある。
- `pkgs/ghostscript-opvp-string.patch`
  - Ghostscript 10.07.1 の `opvp_get_sizestring()` が `NULL` を返す問題を修正する。
  - 修正前は `DeviceResolution=deviceResolution_(null)` と `MediaSize=..._(null)` になっていた。
- `nixos/printing.nix`
  - maeriberry のみ Canon ドライバーを有効化する。
  - NixOS printing module が blacklist する `usblp` を強制的に有効化する。
  - LBP9100C (`04a9:26ea`) 用 udev rule と `/dev/usb/lbp9100c` symlink を作る。
  - `ccpd.conf`、CUPS の `LBP9100C` queue、`ccpd.service` を宣言する。
  - 古い Canon バイナリの `/usr/bin`、`/usr/lib`、`/usr/share` 絶対パスを tmpfiles symlink で補う。
- `non-module/allowUnfreePredicate.nix`
  - `canon-capt` を許可する。

## ビルド状況

次は成功済み。

```sh
nix fmt
nix build --no-link --print-out-paths \
  'path:/home/comavius/projects/dotfiles-v3#nixosConfigurations.maeriberry.config.system.build.toplevel'
```

最後に成功した maeriberry system:

```text
/nix/store/pjzxbfwgzilwv433nkpk7l9k3bfl8spz-nixos-system-maeriberry-26.05.20260710.8f0500b
```

その system が参照する Canon driver:

```text
/nix/store/c6jl4pikr92fygn44ijawb5qm97siv35-canon-capt-2.71
```

最後の Resolution 正規化変更後は maeriberry のみビルドした。AGENTS.md の指示上、完了前には次の両方を改めてビルドすること。

```sh
nixos-rebuild build --flake ".#maeriberry"
nixos-rebuild build --flake ".#usami"
```

この環境から `sudo` は実行しない。switch が必要になったらユーザーへ次を依頼する。

```sh
sudo nixos-rebuild switch --flake "path:/home/comavius/projects/dotfiles-v3#maeriberry"
```

既知の変換失敗が残っているため、現時点では上記 system への switch を急ぐ意味はない。

## ここまでに潰した問題

1. `/dev/usb/lp0` がない
   - NixOS の CUPS module が `usblp` を blacklist していた。
   - `boot.blacklistedKernelModules = lib.mkForce [ ];` と `kernelModules = [ "usblp" ];` で解消。
2. udev symlink ができない
   - device node は `SUBSYSTEM=="usbmisc"`。`usb` ではなかった。
3. Canon filter が Ghostscript を起動できない
   - `pstocapt3` に `/usr/bin/gs` がハードコードされていた。
   - Nix store の Ghostscript path で filter を再ビルドした。
4. `libcanonc3pl.so` が見つからない
   - PPD の `opvpDriver` を絶対 store path にした。
5. 32 bit `c3pldrv` が `/usr/lib/libc3pl.so` を開けない
   - tmpfiles symlink を追加した。
6. OPVP の media/resolution が `(null)`
   - `ghostscript-opvp-string.patch` で修正した。
7. `Resolution=600dpi` が Canon JobInfo に流れる
   - `canon-pstocapt3-resolution.patch` で `Resolution=600` に正規化した。
   - 正規化後も `StartJob` は失敗したため、これだけが主因ではない。

## 重要な比較結果

Canon ドライバー当時の GNU Ghostscript 8.71 を `/tmp` でビルドし、現行 10.07.1 と同じ入力・同じ JobInfo で比較した。

8.71 でも結果は同じだった。

```text
GNU Ghostscript 8.71: Unrecoverable error, exit code 1
Error Response:ReqNo=5, SeqNo=4,opvpErrorNo=-2
40
```

よって Ghostscript の世代差や現行 OPVP の呼び出し順は主因ではない。

また、実験時に CUPS の `onepage-a4.ps` が gzip 圧縮されていることを見落としていた。直接テストには展開済みの正しい PostScript `/tmp/lbp9100c-onepage.ps` を使うこと。先頭は `%!PS-Adobe-3.0`。

## 最新の根本原因候補

GDB で `c3pldrv` を追跡した結果、StartJob の内部関数は `-1` で返るが `errorno` を設定していない。実際に通った失敗分岐は次。

```text
failure_pc=0x8051cfe
```

該当する逆アセンブル上の条件は概ね次の形。

```c
if (ctx_field_1d8 != 0) {
    if (ctx_field_1d0 != 2)
        return -1;  /* 0x8051cfe; errorno は設定されない */

    /* 0x8051e94 以降の追加初期化 */
}
```

つまり次に調べるべきものは `ctx + 0x1d0`, `ctx + 0x1d4`, `ctx + 0x1d8` が何を表すか、および JobInfo のどの属性から設定されるかである。JobInfo 上では特に次が関係しそうだが、まだ対応関係は断定していない。

```text
CNNeedInterpData=True
CNOptDevType=2
CNOptCalibType=3
CNHostDraftMode=10,0,000
```

`CNOptDevType=2` を送っているのに内部 `ctx_field_1d0` が 2 になっていないなら、JobInfo parser がこの値を拾えていない、別のフィールドで上書きしている、または PPD のモデル設定が合っていない可能性がある。

## 再開時の最短手順

### 1. 作業ツリーと runtime を確認

```sh
cd /home/comavius/projects/dotfiles-v3
git status --short
readlink /run/current-system
ls -l /dev/usb/lp0 /dev/usb/lbp9100c /usr/lib/libc3pl.so
systemctl status cups ensure-lbp9100c ccpd --no-pager
lpstat -t
journalctl -u cups -u ensure-lbp9100c -u ccpd -b --no-pager
```

### 2. `0x8051cfe` 分岐の 3 フィールドを直接読む

デバッグ時は Canon RPC client ソースへ StartJob 前の `sleep(60)` を入れ、`c3pldrv` に attach した。ブレークポイントで次を読む。

```gdb
break *0x8051cfe
continue
set $ctx=*(unsigned int*)($ebp-0x4f4)
x/3dw $ctx+0x1d0
x/3wx $ctx+0x1d0
```

同時に StartJob parser のローカル値も確認する。

```gdb
x/wd $ebp-0x54
x/wd $ebp-0x58
x/wd $ebp-0x50
```

逆アセンブル上ではおおよそ次の対応でコピーされている。

```text
[ebp-0x54] -> ctx+0x1d0
[ebp-0x58] -> ctx+0x1d4
[ebp-0x50] -> ctx+0x1d8
```

### 3. JobInfo 属性との対応を絞る

次の順で試すのがよい。

1. `c3pldrv` 内の StartJob parser 近辺 `0x8057074`, `0x80571f4`, `0x8057938`, `0x8054418` の戻り値と出力構造を追う。
2. `ctx+0x1d0` が 2 にならない理由を特定する。
3. PPD の `CNOptDevType`, `CNOptCalibType`, `CNNeedInterpData` を一つずつ変更して direct conversion の出力を比較する。
4. `CNNeedInterpData=False` で `ctx+0x1d8` が 0 になり、`0x8051cfe` を回避できるかを診断目的で試す。
5. 回避できた場合も、生成 CAPT データが正しいかを確認してから設定へ採用する。

### 4. direct conversion の成功条件

現在の失敗時は出力が常に 40 bytes だけ。

成功判定は次の 3 点。

- `Ghostscript ... Unrecoverable error` がない。
- `Error Response:` がない。
- 出力が 40 bytes より十分大きい。

物理プリンターへ送る前に、この direct conversion を必ず通す。

## `/tmp` に残していた調査物

これらは再起動や cleanup で消えるため、存在を前提にしないこと。

```text
/tmp/canon-capt-inspect/
/tmp/ghostscript-8.71/
/tmp/gs871-srcbuild/bin/gs
/tmp/lbp9100c-onepage.ps
/tmp/canon-driver-debug/
/tmp/libcanonc3pl-debug.so
/tmp/run-canon-debug.sh
/tmp/gdb-state.log
/tmp/gdb-startjob.log
/tmp/gdb-startjob-branch.log
```

最後の 3 ログの要点はこの文書へ転記済み。

## 印刷を再開するときの注意

- 古い CUPS job が残っていたら、最初に `lpstat -o` で確認して cancel する。
- direct conversion が通るまで USB へジョブを送らない。
- 実機テストは 1 ページだけ送る。
- `lp` 実行後は CUPS と ccpd の journal、queue state、物理排紙をすべて確認する。
- 物理排紙を確認するまでは、この課題を完了扱いにしない。

