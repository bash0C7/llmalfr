# LLMAlfr

LLMAlfr is a simple and efficient Ruby interface for running local Large Language Models (LLMs). It works with the Ollama API to provide a clean Ruby API.

The name combines "LLM (Large Language Model)" with "alfr," which means "elf" in Old Norse, inspired by the legendary elves' mastery of language manipulation.

## Specification Overview

This gem is designed based on the following specifications:

1. **Simplicity**
   - Provides all functionality through a single Processor class
   - Avoids excessive abstraction or division
   - Contains only `initialize` and `process` methods
   - Simple division of responsibilities

2. **Ollama Integration**
   - Simple LLM execution environment utilizing the Ollama API
   - Different LLMs can be used by simply specifying the model name

3. **Error Handling**
   - Minimal error checking
   - Detailed error handling is the caller's responsibility, exceptions are passed through

4. **Test Design**
   - Simple, readable test code
   - Adoption of the Arrange-Act-Assert (Given-When-Then) pattern
   - Clear naming with intent evident from test names
   - Control based on model execution conditions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'llmalfr'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install llmalfr
```

## Prerequisites and Environment Setup

Before using LLMAlfr, Ollama must be installed. Set up with the following steps:

1. Install Ollama from the [Ollama official site](https://ollama.ai/)

2. Download the Japanese language model:

```bash
ollama pull hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
```

## Usage

```ruby
require 'llmalfr'

# Create a processor with default settings
# Model: hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
# API URL: http://localhost:11434/api
processor = LLMAlfr::Processor.new

# Or specify a particular model and API URL
processor = LLMAlfr::Processor.new('hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest', 'http://localhost:11434/api')

# Define prompt and context
prompt = "Please summarize the following text."
context = "Apple has announced a new MacBook. This model features the M3 chip and offers significantly improved performance compared to previous models. Battery life has also been enhanced, allowing up to 18 hours of use on a single charge."

# Process text (with default options)
result = processor.process(prompt, context)
puts result

# Process text with custom options
custom_options = {
  "temperature" => 0.3,    # Lower temperature for more deterministic output
  "num_predict" => 100     # Shorter response
}
result = processor.process(prompt, context, custom_options)
puts result
```

## Option Settings

The following options are set by default. These can be overridden with the third argument of the `process` method:

```ruby
{
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
```

## Error Handling

LLMAlfr may raise the following exceptions:

- `SocketError`, `Errno::ECONNREFUSED`: When unable to connect to the Ollama API
- `JSON::ParserError`: When failing to parse the API response JSON
- Other HTTP request-related exceptions

It is recommended to implement appropriate exception handling:

```ruby
begin
  result = processor.process(prompt, context)
  puts result
rescue => e
  puts "Error processing text: #{e.message}"
end
```

## Testing

To run tests:

```bash
# Normal test execution (without model execution)
rake test

# Test using actual models
rake test_with_models

# Test with specific model or API endpoint
LLMALFR_TEST_MODEL="hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest" LLMALFR_TEST_API_URL="http://localhost:11434/api" rake test_with_models
```

## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://opensource.org/licenses/Apache-2.0).
