require 'pycall'
require 'pycall/import'
include PyCall::Import

module LLMAlfr
  class Processor
    def initialize(model_path)
      @model_path = model_path
      
      # Basic setup
      raise "Model directory not found: #{model_path}" unless File.directory?(@model_path)
      myenv_path = File.join(Dir.pwd, "myenv")
      site_packages_pattern = File.join(myenv_path, '**/site-packages')
      site_packages_path = Dir.glob(site_packages_pattern).first
      
      # Set up Python environment
      site = PyCall.import_module('site')
      site.addsitedir(site_packages_path)
      
      # Import libraries
      @torch = PyCall.import_module('torch')
      @transformers = PyCall.import_module('transformers')
      
      # Device selection
      if @torch.backends.mps.is_available()
        @device = @torch.device('mps')
      elsif @torch.cuda.is_available()
        @device = @torch.device('cuda')
      else
        @device = @torch.device('cpu')
      end
      
      # Load model and tokenizer
      @model = @transformers.AutoModelForCausalLM.from_pretrained(
        @model_path,
        torch_dtype: @torch.float16,
        device_map: "auto",
        local_files_only: true
      )
      
      @tokenizer = @transformers.AutoTokenizer.from_pretrained(
        @model_path,
        local_files_only: true
      )
    end
    
    def process(prompt, context)
      
      # Basic process approach
      full_prompt = "#{prompt}\n\n#{context}"
      
      # Tokenize directly
      encoded_input = @tokenizer.encode(full_prompt, return_tensors: "pt")
      
      # No grad mode and generate
      no_grad = @torch.no_grad
      output = ""
      
      no_grad.call do
        # Generate text
        generated = @model.generate(
          encoded_input,
          max_length: 200
        )
        
        # Decode output
        output = @tokenizer.decode(generated[0], skip_special_tokens: true)
      end
      
      # Return output removing the original prompt
      if output.length > full_prompt.length
        return output[full_prompt.length..-1].strip
      else
        return "Generated response"
      end
    end
  end
end
