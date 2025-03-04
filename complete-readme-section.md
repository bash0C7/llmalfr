## Offline Model Setup

LLMAlfr is designed to work exclusively with local model files. The library requires you to specify the full path to your local model directory.

### Using Local Model Path

```ruby
# Initialize with a full local path to the model directory
processor = LLMAlfr::Processor.new('/path/to/your/model/directory')
```

### Downloading Model Files

To prepare your model directory, download **all files** from the Hugging Face model repository page:

1. **Visit the official model page**: 
   - Go to [ELYZA-japanese-Llama-2-7b](https://huggingface.co/elyza/ELYZA-japanese-Llama-2-7b/tree/main)

2. **Download all files**:
   - Create a directory for the model: `mkdir -p /path/to/your/model/directory`
   - Download all files from the model page - include every file listed in the repository
   - Yes, you need to download all files shown on the model page to ensure proper functionality

3. **Important model components include**:
   - Configuration files (`config.json`, `generation_config.json`)
   - Model weight files (`pytorch_model-00001-of-00003.bin`, etc.)
   - Tokenizer files (`tokenizer.json`, `tokenizer.model`, etc.)
   - Any additional files specific to the model

### Model Storage Requirements

- ELYZA-japanese-Llama-2-7b: approximately 13GB total
- Model is split across multiple files, with each large weight file being 4-5GB

### Modifying the Processor for Local Path Support

Update the `lib/llmalfr/processor.rb` file to support local paths only:

```ruby
def initialize(model_path)
  @model_path = model_path
  
  # Verify the path exists
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
  elsif @torch.cuda.is_available()
    @device = @torch.device('cuda')
  else
    @device = @torch.device('cpu')
  end
  
  # Load from local directory only
  @model = @transformers.AutoModelForCausalLM.from_pretrained(
    @model_path,
    torch_dtype: @torch.float16,
    trust_remote_code: true,
    local_files_only: true
  ).to(@device)
  
  # Load tokenizer from local directory
  @tokenizer = @transformers.AutoTokenizer.from_pretrained(
    @model_path,
    trust_remote_code: true,
    local_files_only: true
  )
end
```

### Usage Example with Local Path

```ruby
require 'llmalfr'

# Initialize with full path to local model directory
processor = LLMAlfr::Processor.new('/Users/username/models/elyza-japanese-llama-2-7b')

# Define prompt and context
prompt = "以下の文章を要約してください。"
context = "Appleは新しいMacBookを発表しました。このモデルはM3チップを搭載し、前モデルと比較して性能が大幅に向上しています。バッテリー寿命も改善され、一回の充電で最大18時間の使用が可能になりました。"

# Process text
result = processor.process(prompt, context)
puts result
```

### Downloading Large Files

For downloading the large model files:

1. **Use your web browser** to download each file individually from the Hugging Face repository page
2. **Consider using a download manager** for the large weight files (4-5GB each)
3. **Direct download links**:
   Each file can be downloaded directly by appending `/resolve/main/` to the URL path:
   
   ```
   https://huggingface.co/elyza/ELYZA-japanese-Llama-2-7b/resolve/main/pytorch_model-00001-of-00003.bin
   https://huggingface.co/elyza/ELYZA-japanese-Llama-2-7b/resolve/main/pytorch_model-00002-of-00003.bin
   https://huggingface.co/elyza/ELYZA-japanese-Llama-2-7b/resolve/main/pytorch_model-00003-of-00003.bin
   ```
   
   ...and similarly for all other files in the repository.

4. **Verify downloaded files** by checking that your local directory structure matches what's shown on the model page.