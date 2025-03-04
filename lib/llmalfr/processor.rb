require 'pycall'
require 'pycall/import'
include PyCall::Import

module LLMAlfr
  class Processor
    # Initialize the LLM processor
    # @param model_path [String] Full path to the directory containing the model files
    def initialize(model_path)
      @model_path = model_path
      
      # Verify the model directory exists
      raise "Model directory not found: #{model_path}" unless File.directory?(@model_path)
      
      # Find Python virtual environment
      # This assumes a virtual environment is set up in the current directory
      venv_path = File.join(Dir.pwd, 'venv')
      raise "Virtual environment 'venv' not found. Please create it first." unless Dir.exist?(venv_path)
      
      # Find site-packages directory
      site_packages_pattern = File.join(venv_path, '**/site-packages')
      site_packages_path = Dir.glob(site_packages_pattern).first
      raise "Python site-packages directory not found" unless site_packages_path
      
      # Setup Python environment
      site = PyCall.import_module('site')
      site.addsitedir(site_packages_path)
      
      # Import necessary libraries
      pyimport 'torch'
      pyimport 'transformers'
      
      # Set up MPS (Metal Performance Shaders) device for Apple Silicon
      @torch = PyCall.import_module('torch')
      @transformers = PyCall.import_module('transformers')
      
      if @torch.backends.mps.is_available()
        @device = @torch.device('mps')
        puts "Using MPS (Metal Performance Shaders) device for Apple Silicon"
      elsif @torch.cuda.is_available()
        @device = @torch.device('cuda')
        puts "Using CUDA device"
      else
        @device = @torch.device('cpu')
        puts "Using CPU device"
      end
      
      # Load the model from local directory only
      puts "Loading model from directory: #{@model_path}"
      @model = @transformers.AutoModelForCausalLM.from_pretrained(
        @model_path,
        torch_dtype: @torch.float16,
        trust_remote_code: true,
        local_files_only: true  # Force offline mode
      ).to(@device)
      
      # Load tokenizer from local directory only
      puts "Loading tokenizer from directory: #{@model_path}"
      @tokenizer = @transformers.AutoTokenizer.from_pretrained(
        @model_path,
        trust_remote_code: true,
        local_files_only: true  # Force offline mode
      )
      
      puts "Model and tokenizer loaded successfully"
    end
    
    # Process text through the LLM
    # @param prompt [String] The prompt to guide the LLM
    # @param context [String] The context to apply the prompt to
    # @return [String] The processed output from the LLM
    def process(prompt, context)
      # Combine prompt and context
      full_prompt = "#{prompt}\n\n#{context}"
      
      # Tokenize input
      inputs = @tokenizer.encode(
        full_prompt,
        return_tensors: 'pt'
      ).to(@device)
      
      # Generate output
      with_no_grad = @torch.no_grad
      with_no_grad.call do
        outputs = @model.generate(
          inputs,
          max_length: 1024,
          do_sample: true,
          temperature: 0.7,
          top_p: 0.9
        )
      end
      
      # Decode output
      decoded_output = @tokenizer.decode(outputs[0], skip_special_tokens: true)
      
      # Extract the response (removing the original prompt)
      response = decoded_output[full_prompt.length..-1].strip
      
      response
    end
  end
end
