import argparse
from pathlib import Path
from typing import TextIO

# Configuration
ALLOWED_EXTENSIONS = {".yml", ".py"}


def process_file(file_path: Path, output_file: TextIO) -> None:
    """
    Reads a file and appends its content to the output file
    formatted as a Markdown code block.
    """
    # Get extension without the dot for the markdown language tag
    language = file_path.suffix.lstrip(".")

    try:
        content = file_path.read_text(encoding="utf-8")
        output_file.write(f"### {file_path}\n")
        output_file.write(f"```{language}\n")
        output_file.write(content)
        # Ensure content ends with a newline before closing block
        if not content.endswith("\n"):
            output_file.write("\n")
        output_file.write("```\n\n")
    except Exception as e:
        print(f"Skipping {file_path}: {e}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Consolidate code files into a single Markdown file."
    )
    parser.add_argument("output_file", type=Path, help="Path to the destination file")
    args = parser.parse_args()

    output_path: Path = args.output_file

    try:
        with output_path.open("w", encoding="utf-8") as output_file:
            # Recursively find all files in the current directory
            for file_path in Path(".").rglob("*"):
                # Check if it's a file, matches extension, and isn't the output file itself
                if (
                    file_path.is_file()
                    and file_path.suffix in ALLOWED_EXTENSIONS
                    and file_path.resolve() != output_path.resolve()
                ):
                    process_file(file_path, output_file)
    except IOError as e:
        print(f"Error opening output file: {e}")


if __name__ == "__main__":
    main()
