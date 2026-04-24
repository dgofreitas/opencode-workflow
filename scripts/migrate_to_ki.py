import os
import json
import shutil
from pathlib import Path

def create_ki(src_path, context_dir, dest_base_dir):
    # Determine the relative path from the context directory
    # e.g., 'core/essential-patterns.md'
    rel_path = src_path.relative_to(context_dir)
    
    # Generate KI name by replacing path separators with underscores
    # e.g., 'core_essential-patterns'
    ki_name = str(rel_path.with_suffix('')).replace(os.sep, '_').replace('-', '_')
    
    # Target directories
    ki_dir = dest_base_dir / ki_name
    artifacts_dir = ki_dir / 'artifacts'
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy the markdown file
    dest_file = artifacts_dir / src_path.name
    shutil.copy2(src_path, dest_file)
    
    # Create a basic title and summary
    title = src_path.stem.replace('-', ' ').title()
    summary = f"OpenCode context for {title}. Contains standards and rules previously used in the OpenCode workflow."
    
    # Create metadata.json
    metadata = {
        "title": title,
        "summary": summary,
        "created_at": "2026-04-20T16:00:00Z",
        "updated_at": "2026-04-20T16:00:00Z",
        "references": []
    }
    
    with open(ki_dir / 'metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
        
    print(f"Created KI: {ki_name}")

def main():
    base_dir = Path('/home/diogo.freitas/dgo/opencode-workflow')
    context_dir = base_dir / 'context'
    dest_base_dir = base_dir / 'antigravity' / 'knowledge'
    
    if not context_dir.exists():
        print(f"Context directory not found at {context_dir}")
        return
        
    # Walk through context directory
    for src_path in context_dir.rglob('*.md'):
        create_ki(src_path, context_dir, dest_base_dir)

if __name__ == '__main__':
    main()
