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
      
      # Find virtual environment path (simplified)
      myenv_path = File.join(Dir.pwd, "myenv")
      fail "Virtual environment 'myenv' not found" unless Dir.exist?(myenv_path)
      
      # Find Python site-packages (more efficiently)
      site_packages_pattern = File.join(myenv_path, '**/site-packages')
      site_packages_path = Dir.glob(site_packages_pattern).first
      fail "Python site-packages directory not found" unless site_packages_path
      
      # Set Python path for resource tracker
      ENV['PYTHONPATH'] = site_packages_path

      # Add site directory
      site = PyCall.import_module('site')
      site.addsitedir(site_packages_path)
      
      # Import multiprocessing module for resource tracker
      @multiprocessing = PyCall.import_module('multiprocessing')
      @resource_tracker = PyCall.import_module('multiprocessing.resource_tracker')

      # Import necessary libraries
      pyimport 'torch'
      pyimport 'transformers'
      
      # Set up device for computation
      @torch = PyCall.import_module('torch')
      @transformers = PyCall.import_module('transformers')
      
      # Store device name as string instead of device object
      if @torch.backends.mps.is_available()
        @device_name = 'mps'
        puts "Using MPS (Metal Performance Shaders) device for Apple Silicon"
      elsif @torch.cuda.is_available()
        @device_name = 'cuda'
        puts "Using CUDA device for NVIDIA GPU"
      else
        @device_name = 'cpu'
        puts "Using CPU device"
      end
      
      # Load the model - use "auto" for device_map
      puts "Loading model from directory: #{@model_path}"
      @model = @transformers.AutoModelForCausalLM.from_pretrained(
        @model_path,
        torch_dtype: @torch.float16,
        trust_remote_code: false,
        device_map: "auto",  # Use "auto" instead of a string device type
        local_files_only: true
      )
      
      # Load tokenizer
      @tokenizer = @transformers.AutoTokenizer.from_pretrained(
        @model_path,
        trust_remote_code: false,
        local_files_only: true
      )
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
      )
      
      # Move inputs to device using string name instead of device object
      inputs = inputs.to(@device_name)  # Pass device name as string
      
      outputs = []
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
