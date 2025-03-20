# LLMAlfr

LLMAlfr (エルエルエム・アールブ) はローカルの大規模言語モデル(LLM)を実行するためのシンプルで効率的なRuby用インターフェースです。Ollama APIと連携し、クリーンなRuby APIを提供します。

名前の由来は「LLM (Large Language Model)」と古ノルド語で「エルフ」を意味する "alfr" の組み合わせであり、伝説のエルフが言葉を操る能力に長けていたことにちなんでいます。

## 仕様概要

このgemは以下の仕様に基づいて設計されています：

1. **シンプルさ**
   - Processorクラス一つで全ての機能を提供
   - 過剰な抽象化や分割を行わない
   - メソッドは`initialize`と`process`のみ
   - シンプルな責務分担

2. **Ollama連携**
   - Ollama APIを活用したシンプルなLLM実行環境
   - モデル名を指定するだけで異なるLLMを使用可能

3. **エラーハンドリング**
   - 最小限のエラーチェック
   - 詳細なエラーハンドリングは呼び出し側の責務とし、例外は投げっぱなし

4. **テスト設計**
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

LLMAlfr を使用する前に、Ollamaがインストールされている必要があります。以下の手順でセットアップしてください：

1. [Ollama公式サイト](https://ollama.ai/)からOllamaをインストール

2. 日本語モデルをダウンロード:

```bash
ollama pull hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
```

## 使用方法

```ruby
require 'llmalfr'

# デフォルト設定でプロセッサを作成
# モデル: hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
# API URL: http://localhost:11434/api
processor = LLMAlfr::Processor.new

# または特定のモデルとAPI URLを指定
processor = LLMAlfr::Processor.new('hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest', 'http://localhost:11434/api')

# プロンプトとコンテキストを定義
prompt = "以下の文章を要約してください。"
context = "Appleは新しいMacBookを発表しました。このモデルはM3チップを搭載し、前モデルと比較して性能が大幅に向上しています。バッテリー寿命も改善され、一回の充電で最大18時間の使用が可能になりました。"

# テキストを処理（デフォルトオプション）
result = processor.process(prompt, context)
puts result

# カスタムオプションでテキストを処理
custom_options = {
  "temperature" => 0.3,    # より決定論的な出力のための低いtemperature
  "num_predict" => 100     # より短い応答
}
result = processor.process(prompt, context, custom_options)
puts result
```

## オプション設定

以下のオプションがデフォルトで設定されています。これらは`process`メソッドの第3引数で上書きできます：

```ruby
{
  "temperature" => 0.6,           # 日本語の一貫性を高めるための低いtemperature
  "top_p" => 0.88,                # 文脈関連性向上のための軽減
  "top_k" => 40,                  # 語彙選択を制限するために削減
  "num_predict" => 512,           # 日本語の完全な文章のために増加
  "repeat_penalty" => 1.2,        # 繰り返しにペナルティ（日本語に重要）
  "presence_penalty" => 0.2,      # 同じトピックの繰り返しを抑制
  "frequency_penalty" => 0.2,     # 単語選択のさらなる多様性
  "stop" => ["\n\n", "。\n"],     # 日本語に適した停止シーケンス
  "seed" => 0,                    # 再現性のためのランダムシード（-1でランダム）
}
```

## エラーハンドリング

LLMAlfrは以下の例外を発生させる可能性があります：

- `SocketError`, `Errno::ECONNREFUSED`: Ollama APIに接続できない場合
- `JSON::ParserError`: APIレスポンスのJSONパースに失敗した場合
- その他のHTTPリクエスト関連の例外

適切な例外処理を実装することをお勧めします：

```ruby
begin
  result = processor.process(prompt, context)
  puts result
rescue => e
  puts "Error processing text: #{e.message}"
end
```

## テスト

テストを実行するには：

```bash
# 通常のテスト実行（モデル実行なし）
rake test

# モデルを実際に使用するテスト
rake test_with_models

# 特定のモデルやAPIエンドポイントでテスト
LLMALFR_TEST_MODEL="hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest" LLMALFR_TEST_API_URL="http://localhost:11434/api" rake test_with_models
```

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件に基づいてオープンソースとして利用可能です。
