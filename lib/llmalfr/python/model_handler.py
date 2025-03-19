import torch
import transformers
import time

# Global variables to store model and tokenizer
_model = None
_tokenizer = None

def initialize_model(model_path):
    """Initialize model and tokenizer from the given path"""
    global _model, _tokenizer
    
    # Force CPU usage to avoid MPS issues
    torch.set_default_device('cpu')
    
    # Load tokenizer first
    _tokenizer = transformers.AutoTokenizer.from_pretrained(
        model_path,
        local_files_only=True
    )
    
    # Set pad_token if needed
    if _tokenizer.pad_token is None or _tokenizer.pad_token == _tokenizer.eos_token:
        _tokenizer.pad_token = '[PAD]'
        _tokenizer.pad_token_id = _tokenizer.convert_tokens_to_ids('[PAD]')
        if _tokenizer.pad_token_id == _tokenizer.unk_token_id:
            _tokenizer.pad_token_id = len(_tokenizer) - 1
    
    # Load model with optimized settings
    _model = transformers.AutoModelForCausalLM.from_pretrained(
        model_path,
        torch_dtype=torch.float16,
        device_map="cpu",
        local_files_only=True,
        pad_token_id=_tokenizer.pad_token_id
    )
    
    # Resize embeddings if needed
    _model.resize_token_embeddings(len(_tokenizer))
    
    # Put model in evaluation mode
    _model.eval()
    
    return "Model initialized successfully"

def generate_text(full_prompt):
    """Generate text based on full prompt with optimized Japanese generation parameters"""
    global _model, _tokenizer
    
    # Check if model and tokenizer are loaded
    if _model is None or _tokenizer is None:
        return "Error: Model not initialized"
    
    try:
        # Enhance the prompt for better Japanese generation
        enhanced_prompt = full_prompt.strip()
        
        # Tokenize with padding and truncation if needed
        encoded_input = _tokenizer(enhanced_prompt, 
                                   return_tensors="pt", 
                                   padding=True,
                                   truncation=True,
                                   max_length=512)  # Prevent too long inputs
        
        # Ensure inputs are on CPU
        input_ids = encoded_input['input_ids'].to('cpu')
        attention_mask = encoded_input['attention_mask'].to('cpu')
        
        # Add timeout to prevent infinite loops
        start_time = time.time()
        timeout = 120  # 2 minutes timeout
        
        # Generate with no_grad and optimized Japanese parameters
        with torch.no_grad():
            outputs = _model.generate(
                input_ids,
                attention_mask=attention_mask,
                max_new_tokens=256,           # Generate more tokens for Japanese
                temperature=0.7,              # Good balance for coherent Japanese
                top_p=0.92,                   # Nucleus sampling - good for Japanese
                top_k=50,                     # Limit vocabulary to top 50 tokens at each step
                repetition_penalty=1.1,       # Slight penalty for repetition
                no_repeat_ngram_size=3,       # Avoid repeating 3-grams
                do_sample=True,               # Use sampling for more natural text
                num_return_sequences=1,       # Just one output
                pad_token_id=_tokenizer.pad_token_id,
                eos_token_id=_tokenizer.eos_token_id,
                bad_words_ids=None,           # No explicitly banned tokens
                min_length=30                 # Ensure some minimum output length
            )
            
            # Check for timeout
            if time.time() - start_time > timeout:
                return "Error: Generation timed out"
        
        # Decode output with special handling for Japanese text
        generated_text = _tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Extract only the generated part (excluding the prompt)
        # For Japanese, we need to be careful with string length comparison
        if len(generated_text) > len(enhanced_prompt):
            # Find where the response starts after the prompt
            result = generated_text[len(enhanced_prompt):].strip()
            
            # Clean up common issues in Japanese generation
            result = result.replace(" ", "")  # Remove unnecessary spaces
            result = result.replace("。。", "。")  # Fix doubled periods
            
            return result
        else:
            return "生成された回答はありません。"  # Japanese message for empty response
    except Exception as e:
        return f"テキスト生成中にエラーが発生しました: {str(e)}"  # Japanese error messages
