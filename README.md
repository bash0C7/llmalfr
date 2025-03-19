# LLMAlfr

LLMAlfr (エルエルエム・アールブ) はApple Silicon搭載Macでローカル大規模言語モデル(LLM)を実行するためのシンプルで効率的なRuby用インターフェースです。PyCallを活用してPythonベースのLLMライブラリと連携し、クリーンなRuby APIを提供します。

名前の由来は「LLM (Large Language Model)」と古ノルド語で「エルフ」を意味する "alfr" の組み合わせであり、伝説のエルフが言葉を操る能力に長けていたことにちなんでいます。

## 仕様概要

このgemは以下の仕様に基づいて設計されています：

1. **シンプルさ**
   - Processorクラス一つで全ての機能を提供
   - 過剰な抽象化や分割を行わない
   - メソッドは`initialize`と`process`のみ
   - シンプルな責務分担

2. **Apple Silicon最適化**
   - Metal Performance Shaders (MPS)の自動検出と活用
   - トーチバックエンドの自動選択

3. **Python/LLM連携**
   - PyCallを使用したシームレスなPythonモデル連携
   - モデル名を指定するだけで異なるLLMを使用可能

4. **エラーハンドリング**
   - 最小限のエラーチェック
   - 詳細なエラーハンドリングは呼び出し側の責務とし、例外は投げっぱなし

5. **テスト設計**
   - シンプルで読みやすいテストコード
   - Arrange-Act-Assert (Given-When-Then) パターンの採用
   - テスト名から意図が明確になる命名
   - モデル実行条件による制御

## インストール

アプリケーションのGemfileに以下の行を追加:

```ruby
gem 'llmalfr'
```

そして実行:

```bash
$ bundle install
```

または自分でインストール:

```bash
$ gem install llmalfr
```

## 前提条件と環境のセットアップ

LLMAlfr を使用する前に、Python環境が必要です。手動で以下のようにセットアップしてください：

```bash
# 仮想環境の作成
pyenv exec python -m venv myenv

# 仮想環境のアクティベート
source myenv/bin/activate  # Windowsの場合: myenv\Scripts\activate

# 必要なPythonパッケージのインストール
pip install --upgrade pip
pip install torch transformers sentencepiece
pip install 'accelerate>=0.26.0'
```

M1/M2/M3チップ搭載のMacでは、MPSが自動的に使用されます。

## 使用方法

```ruby
require 'llmalfr'

# 使用したいモデルでプロセッサを作成
processor = LLMAlfr::Processor.new('elyza/ELYZA-japanese-Llama-2-7b')

# プロンプトとコンテキストを定義
prompt = "以下の文章を要約してください。"
context = "Appleは新しいMacBookを発表しました。このモデルはM3チップを搭載し、前モデルと比較して性能が大幅に向上しています。バッテリー寿命も改善され、一回の充電で最大18時間の使用が可能になりました。"

# テキストを処理
result = processor.process(prompt, context)
puts result
```

## オフラインモデルのセットアップ

LLMAlfr はローカルモデルファイルのみで動作するように設計されています。ライブラリはローカルモデルディレクトリへのフルパスを指定する必要があります。

### ローカルモデルパスの使用

```ruby
# モデルディレクトリへのフルパスで初期化
processor = LLMAlfr::Processor.new('/path/to/your/model/directory')
```

### モデルファイルのダウンロード

モデルディレクトリを準備するには、Hugging Face モデルリポジトリページから**すべてのファイル**をダウンロードしてください：

1. **公式モデルページにアクセス**: 
   - [ELYZA-japanese-Llama-2-7b](https://huggingface.co/elyza/ELYZA-japanese-Llama-2-7b/tree/main) にアクセス

2. **すべてのファイルをダウンロード**:
   - モデル用のディレクトリを作成: `mkdir -p /path/to/your/model/directory`
   - モデルページからすべてのファイルをダウンロード - リポジトリにリストされているすべてのファイルを含めてください
   - 適切な機能を確保するために、モデルページに表示されているすべてのファイルをダウンロードする必要があります

3. **重要なモデルコンポーネント**:
   - 設定ファイル (`config.json`, `generation_config.json`)
   - モデルの重みファイル (`pytorch_model-00001-of-00003.bin` など)
   - トークナイザーファイル (`tokenizer.json`, `tokenizer.model` など)
   - モデル固有の追加ファイル

### モデルストレージ要件

- ELYZA-japanese-Llama-2-7b: 合計約13GB
- モデルは複数のファイルに分割され、各大型重みファイルは4-5GBです

## テスト

テストを実行するには：

```bash
# 通常のテスト実行（モデル実行なし）
rake test

# モデルを実際に使用するテスト
rake test_with_models
```

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件に基づいてオープンソースとして利用可能です。
