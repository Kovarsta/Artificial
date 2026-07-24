# Ollama Modelfile Usage Guide

## Creating a Model from a Modelfile

```bash
# Build a model from a Modelfile
ollama create model-name -f Modelfile

# Example
ollama create charlotte-general -f CharlotteQwen3.6-35b/Modelfile.general
```

## Listing Models

```bash
# List all local models
ollama list
```

## Running a Model

```bash
# Interactive chat
ollama run model-name

# Single prompt
ollama run model-name "your prompt here"
```

## Updating a Model

To update a model, modify the Modelfile and recreate it with the same name:

1. Edit the Modelfile parameters
2. Run `ollama create` with the same model name

```bash
# Edit Modelfile, then recreate
ollama create model-name -f Modelfile
```

This overwrites the existing model with the updated configuration.

## Deleting a Model

```bash
# Remove a model
ollama rm model-name
```

## Pulling Remote Models

```bash
# Pull a model from the Ollama registry
ollama pull model-name
```
