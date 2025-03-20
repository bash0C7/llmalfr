require 'test/unit'
require 'llmalfr'

class TestProcessor < Test::Unit::TestCase
  def setup
    # Use default model name or override from environment
    @model_name = ENV['LLMALFR_TEST_MODEL'] || 'hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest'
    
    # Use default API URL or override from environment
    @api_url = ENV['LLMALFR_TEST_API_URL'] || 'http://localhost:11434/api'
    
    # Initialize processor
    @processor = LLMAlfr::Processor.new(@model_name, @api_url)
  end
  
  def test_processor_initialization
    # Assert: processor should be correctly initialized
    assert_instance_of(LLMAlfr::Processor, @processor)
  end
  
  def test_text_summarization
    # Skip actual model tests unless enabled
    omit "Skipping model execution tests (set LLMALFR_RUN_MODEL_TESTS=true to enable)" unless ENV['LLMALFR_RUN_MODEL_TESTS'] == 'true'
    
    # Arrange: prepare test prompt and context
    prompt = "以下の文章を要約してください。"
    context = "Appleは新しいMacBookを発表しました。このモデルはM3チップを搭載し、前モデルと比較して性能が大幅に向上しています。バッテリー寿命も改善され、一回の充電で最大18時間の使用が可能になりました。"
    options = {
      "temperature" => 0.6,           # Lower temperature for more coherent Japanese
      "top_p" => 0.88,                # Slight reduction for better context relevance
      "top_k" => 40,                  # Reduced to limit vocabulary choices
      "num_predict" => 512,           # Increased for better complete sentences in Japanese
      "repeat_penalty" => 1.2,        # Penalize repetitions (important for Japanese)
      "presence_penalty" => 0.2,      # Discourage repeating the same topics
      "frequency_penalty" => 0.2,     # Additional variety in word choice
      "stop" => ["\n\n", "。\n"],     # Stop sequences appropriate for Japanese
      "seed" => 0,                    # Random seed for reproducibility (-1 for random)
    }    
    # Act: execute summarization
    result = @processor.process(prompt, context, options)
    
    # Assert: result should meet expectations
    assert_equal("価格は1799ドルからスタートします。", result)
  end
  
  def test_transcription_formatting
    # Skip actual model tests unless enabled
    omit "Skipping model execution tests (set LLMALFR_RUN_MODEL_TESTS=true to enable)" unless ENV['LLMALFR_RUN_MODEL_TESTS'] == 'true'
    
    # Arrange: prepare transcription text and prompt
    transcribed_text = "えーと、今日のミーティングではですね、第一四半期の売上について話し合いたいと思います。えっと、前年比で約15パーセント増加しており、特に新規顧客からの注文が増えています。あのー、詳細な数字については後ほど資料を送りますが、大まかな傾向としては好調と言えるでしょう。"
    prompt = "以下の文字起こしテキストをフィラーワードを削除して整形してください。"
    options = {
      "temperature" => 0.6,           # Lower temperature for more coherent Japanese
      "top_p" => 0.88,                # Slight reduction for better context relevance
      "top_k" => 40,                  # Reduced to limit vocabulary choices
      "num_predict" => 512,           # Increased for better complete sentences in Japanese
      "repeat_penalty" => 1.2,        # Penalize repetitions (important for Japanese)
      "presence_penalty" => 0.2,      # Discourage repeating the same topics
      "frequency_penalty" => 0.2,     # Additional variety in word choice
      "stop" => ["\n\n", "。\n"],     # Stop sequences appropriate for Japanese
      "seed" => 0,                    # Random seed for reproducibility (-1 for random)
    }    
    # Act: execute formatting
    result = @processor.process(prompt, transcribed_text, options)
    
    # Assert: result should meet expectations
    assert_equal("次回のミーティングではですね、この第一四半期の結果を受けて、新しい目標や戦略を考慮した上で、第二四半期以降の方針について話し合いたいと思います。", result)
  end
  
  def test_invalid_api_url
    # Arrange: create processor with invalid API URL
    processor = LLMAlfr::Processor.new(@model_name, "http://invalid-url:99999")
    
    # Act & Assert: should raise any exception
    assert_raise do
      processor.process("Test prompt", "Test context")
    end
  end
end
