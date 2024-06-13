# Zcamex

**画像データのPingPong通信デモアプリ**

## 動作環境
- Erlang 26 以降
- Elixir 1.16 以降

## 準備
```sh
$ git clone git@github.com:b5g-ex/zcamex.git
$ cd zcamex
$ mix setup
```
## 起動
事前に [`simple_echo`](https://github.com/b5g-ex/simple_echo) (画像返却用 HTTP Backend)を起動しておくこと。
```sh
# 全設定がデフォルト値の場合
$ ./start.sh

# 設定を変更する場合 (例: MEC_HTTP_BACKEND_URL を変更)
$ MEC_HTTP_BACKEND_URL="http://{your host}/echo" ./start.sh
```
ブラウザから [`http://localhost:4000`](http://localhost:4000) にアクセスする。  
別ホストからアクセスする場合は `https://{ip address of zcamex host}:4001` にアクセスする。

## 設定 (環境変数)
| 項目 | 初期値 | 説明 |
| --- | --- | --- |
| MEC_HTTP_BACKEND_URL | "http://localhost:4444/echo" | MECの `HTTP Backend` のURL |
| CLOUD_HTTP_BACKEND_URL | "http://localhost:4444/echo" | Cloudの `HTTP Backend` のURL |
