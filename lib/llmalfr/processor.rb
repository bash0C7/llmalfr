require 'pycall'
require 'pycall/import'
include PyCall::Import

module LLMAlfr
  class Processor
    def initialize(model_path)
      @model_path = model_path
      
      # Setup Python environment
      myenv_path = File.join(Dir.pwd, "myenv")
      site_packages_pattern = File.join(myenv_path, '**/site-packages')
      site_packages_path = Dir.glob(site_packages_pattern).first
      site = PyCall.import_module('site')
      site.addsitedir(site_packages_path)
      
      # Load Python script from external file
      py_file_path = File.expand_path('../python/model_handler.py', __FILE__)
      PyCall.exec(File.read(py_file_path))
      
      # Initialize model using the loaded Python functions
      main = PyCall.import_module('__main__')
      result = main.initialize_model(@model_path)
      
      # Verify initialization
      raise "Failed to initialize model" unless result == "Model initialized successfully"
    end
    
    def process(prompt, context)
      # Combine prompt and context
      full_prompt = "#{prompt}\n\n#{context}"
      
      # Generate text using Python function
      main = PyCall.import_module('__main__')
      main.generate_text(full_prompt)
    end
  end
end
