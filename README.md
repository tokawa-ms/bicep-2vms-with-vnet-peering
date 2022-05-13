# SRT-transmit-thru-azure-test
SRT を利用して二拠点間の（国際）映像伝送のテストを行うための環境を Azure にデプロイする bicep ファイルと、SRT ならびに ffmpeg のビルド自動化用のスクリプトです。

## 何をやるのか
- ピアリングされた 2 つの仮想ネットワークをデプロイ
- それぞれの仮想ネットワークに一台ずつ VM を立ち上げる
- SRT と ffmpeg を SRT 有効化した状態でソースコードからビルド
- 映像伝送用に UDP のバッファの拡張

## How to Deploy
### Azure 環境への VM ならびに仮想ネットワークのデプロイ
以下のボタンをクリックすることで、自分の Azure 環境にデプロイするための UI が開きます。
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftokawa-ms%2Fsrt-transmit-thru-azure-test%2Fmain%2Ftwo-vms-with-vnet-peering.json)

