import os
import json
import shutil
import re
from pathlib import Path

def get_purpose_from_markdown(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        # First, try to find a "Purpose:" line
        for line in lines:
            if '**Purpose**:' in line or 'Purpose:' in line:
                return line.split('Purpose**:')[-1].split('Purpose:')[-1].strip()
                
        # If not found, look for the first non-header, non-comment, non-empty line
        for line in lines:
            stripped = line.strip()
            if not stripped: continue
            if stripped.startswith('<!--') or stripped.startswith('#') or stripped.startswith('---'): continue
            
            # If we found a real text line, use it as fallback
            return stripped[:250] + ('...' if len(stripped) > 250 else '')
            
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        
    return None

def main():
    base_dir = Path('/home/diogo.freitas/dgo/opencode-workflow/antigravity/knowledge')
    
    if not base_dir.exists():
        print(f"Knowledge directory not found at {base_dir}")
        return
        
    deleted_count = 0
    updated_count = 0
    
    for ki_dir in base_dir.iterdir():
        if not ki_dir.is_dir(): continue
        
        # Determine if it's a navigation KI
        is_navigation = False
        if ki_dir.name.endswith('_navigation'):
            is_navigation = True
        
        # Check artifacts for a navigation.md file
        artifacts_dir = ki_dir / 'artifacts'
        md_file = None
        if artifacts_dir.exists():
            for f in artifacts_dir.iterdir():
                if f.name == 'navigation.md':
                    is_navigation = True
                elif f.suffix == '.md':
                    md_file = f
                    
        if is_navigation:
            print(f"🗑️ Deleting navigation KI: {ki_dir.name}")
            shutil.rmtree(ki_dir)
            deleted_count += 1
            continue
            
        # If not deleted, we optimize the summary
        if md_file and md_file.exists():
            purpose = get_purpose_from_markdown(md_file)
            if purpose:
                metadata_path = ki_dir / 'metadata.json'
                if metadata_path.exists():
                    with open(metadata_path, 'r', encoding='utf-8') as f:
                        metadata = json.load(f)
                        
                    old_summary = metadata.get('summary', '')
                    new_summary = f"{purpose} (Extracted from {md_file.name})"
                    
                    if old_summary != new_summary:
                        metadata['summary'] = new_summary
                        with open(metadata_path, 'w', encoding='utf-8') as f:
                            json.dump(metadata, f, indent=2)
                        print(f"✅ Updated summary for: {ki_dir.name}")
                        print(f"   -> {new_summary}")
                        updated_count += 1
                        
    print(f"\nOptimization complete! Deleted {deleted_count} navigation KIs, Updated {updated_count} summaries.")

if __name__ == '__main__':
    main()
