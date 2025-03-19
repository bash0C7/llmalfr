require 'test/unit'
require 'llmalfr'

class TestProcessor < Test::Unit::TestCase
  def setup
    # 実際のテストで使うモデル名
    @model_name = 'elyza/ELYZA-japanese-Llama-2-7b'
    
    # 環境変数でモデル名を上書き可能に
    @model_name = ENV['LLMALFR_TEST_MODEL'] if ENV['LLMALFR_TEST_MODEL']
    
    # プロセッサーの初期化
    @processor = LLMAlfr::Processor.new(@model_name)
  end
  
  def test_processor_initialization
    # Assert: プロセッサが正しく初期化されていること
    assert_instance_of(LLMAlfr::Processor, @processor)
  end
  
  def test_text_summarization
    # Skip actual model tests unless enabled
    return unless ENV['LLMALFR_RUN_MODEL_TESTS'] == 'true'
    
    # Arrange: テスト用のプロンプトとコンテキストを準備
    prompt = "以下の文章を要約してください。"
    context = "Appleは新しいMacBookを発表しました。このモデルはM3チップを搭載し、前モデルと比較して性能が大幅に向上しています。バッテリー寿命も改善され、一回の充電で最大18時間の使用が可能になりました。"
    
    # Act: 要約処理を実行
    result = @processor.process(prompt, context)
    
    # Assert: 結果が期待通りであること
    assert_not_nil(result)
    assert_instance_of(String, result)
    assert_equal("Generated response????", result)
  end
  
  def test_transcription_formatting
    # Skip actual model tests unless enabled
    return unless ENV['LLMALFR_RUN_MODEL_TESTS'] == 'true'
    
    # Arrange: 文字起こしテキストとプロンプトを準備
    transcribed_text = "えーと、今日のミーティングではですね、第一四半期の売上について話し合いたいと思います。えっと、前年比で約15パーセント増加しており、特に新規顧客からの注文が増えています。あのー、詳細な数字については後ほど資料を送りますが、大まかな傾向としては好調と言えるでしょう。"
    prompt = "以下の文字起こしテキストをフィラーワードを削除して整形してください。"
    
    # Act: 整形処理を実行
    result = @processor.process(prompt, transcribed_text)
    
    # Assert: 結果が期待通りであること
    assert_not_nil(result)
    assert_instance_of(String, result)
    assert_equal("Generated response????", result)
  end
end
