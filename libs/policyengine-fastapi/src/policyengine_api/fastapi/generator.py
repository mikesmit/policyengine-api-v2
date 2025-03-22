"""
Generic OpenAPI Schema Generator

This script generates an OpenAPI schema from a FastAPI application.
It dynamically imports the FastAPI app based on a provided module path.
"""

import argparse
import importlib
import json
import os
from pathlib import Path
import sys


def generate_openapi_schema(module_path:str, output_file:str, app_name:str="app"):
    """
    Generate an OpenAPI schema from a FastAPI application.
    
    Args:
        module_path (str): The module path where the FastAPI app is located (e.g., "policyengine_api_full.main")
        app_name (str): The name of the FastAPI app variable in the module (default: "app")
        output_file (str): Path to save the OpenAPI schema (if None, prints to stdout)
    """
    try:
        project_path = str(Path("./").resolve())
        print(f"Adding {project_path} to system path")
        sys.path.insert(0,project_path)
        # Import the module dynamically
        print(f"Attempting to load module {module_path}")
        module = importlib.import_module(module_path)
        
        print(f"Getting app {app_name} from module")
        # Get the FastAPI app from the module
        app = getattr(module, app_name)
        
        print(f"generating the schema")
        # Generate the OpenAPI schema
        schema = app.openapi()
        
        print(f"Making the output file: {output_file}")

        with open(output_file, 'w') as f:
            json.dump(schema, f, indent=4)
        print(f"OpenAPI schema generated at: {output_file}")
    
    except ImportError:
        print(f"Error: Could not import module '{module_path}'", file=sys.stderr)
        sys.exit(1)
    except AttributeError:
        print(f"Error: Could not find '{app_name}' in module '{module_path}'", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Generate OpenAPI schema from a FastAPI application")
    parser.add_argument("module_path", help="Module path where the FastAPI app is located (e.g., 'package.module')")
    parser.add_argument("--app-name", type=str, default="app", help="Name of the FastAPI app variable (default: 'app')")
    parser.add_argument("--output", "-o", type=str, required=True, help="Output file path")
    
    args = parser.parse_args()

    print(f"output is #{args.output}")
    
    generate_openapi_schema(args.module_path, output_file=args.output, app_name=args.app_name)


if __name__ == "__main__":
    main()