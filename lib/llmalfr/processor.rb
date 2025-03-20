require 'net/http'
require 'uri'
require 'json'

module LLMAlfr
  class Processor
    # Default options for Ollama API
    DEFAULT_OPTIONS = {
      "temperature" => 0.6,           # Lower temperature for more coherent Japanese
      "top_p" => 0.88,                # Slight reduction for better context relevance
      "top_k" => 40,                  # Reduced to limit vocabulary choices
      "num_predict" => 2048,           # Increased for better complete sentences in Japanese
      "repeat_penalty" => 1.2,        # Penalize repetitions (important for Japanese)
      "presence_penalty" => 0.2,      # Discourage repeating the same topics
      "frequency_penalty" => 0.2,     # Additional variety in word choice
      "stop" => ["\n\n", "。\n"],     # Stop sequences appropriate for Japanese
      "seed" => 0,                    # Random seed for reproducibility (-1 for random)
    }.freeze

    # Initialize with model name and API URL
    # @param model_name [String] The Ollama model name
    # @param api_url [String] The base URL for Ollama API
    def initialize(model_name = "hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest", api_url = "http://localhost:11434/api")
      @model_name = model_name
      @api_base_url = api_url
    end
    
    # Process text with LLM
    # @param prompt [String] The instruction for the model
    # @param context [String] The context or content to process
    # @param options [Hash] Custom options to override defaults
    # @return [String] The generated response
    def process(prompt, context, options = {})
      # Combine prompt and context
      full_prompt = "#{prompt}\n\n#{context}"
      
      # Call Ollama API
      response = generate_from_ollama(full_prompt, options)
      response["response"]
    end
    
    private
    
    # Call Ollama API with prompt and options
    # @param prompt [String] The full prompt to send
    # @param custom_options [Hash] Custom options to override defaults
    # @return [Hash] The parsed JSON response
    def generate_from_ollama(prompt, custom_options = {})
      uri = URI.parse("#{@api_base_url}/generate")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      
      # Merge default options with custom options
      merged_options = DEFAULT_OPTIONS.merge(custom_options)
      
      request.body = JSON.dump({
        "model" => @model_name,
        "prompt" => prompt,
        "stream" => false, # Important: disable streaming
        "options" => merged_options
      })
      
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      
      JSON.parse(response.body)
    end
  end
end
