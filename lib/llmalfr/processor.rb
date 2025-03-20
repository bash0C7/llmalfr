require 'net/http'
require 'uri'
require 'json'

module LLMAlfr
  class Processor
    def initialize(model_path)
      @model_name = "hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest"  #File.basename(model_path)
      @api_base_url = "http://localhost:11434/api"
    end
    
    def process(prompt, context)
      # Combine prompt and context
      full_prompt = "#{prompt}\n\n#{context}"
      
      # Call Ollama API
      response = generate_from_ollama(full_prompt)
      response["response"]
    end
    
    private
    
    def generate_from_ollama(prompt)
      uri = URI.parse("#{@api_base_url}/generate")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "model" => @model_name,
        "prompt" => prompt,
        "stream" => false, # 重要: ストリーミングを無効化
        "options" => {
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
      })
      
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      
      JSON.parse(response.body)
    end
  end
end

