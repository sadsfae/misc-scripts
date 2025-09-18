#!/usr/bin/env python3
# Generate an AI prompt dump for code review from a gerrithub patchset
# e.g.
# python gerrit_ai_prompt3.py https://review.gerrithub.io/c/redhat-performance/quads/+/1222441 -o review_prompt.txt -t help_review

import requests
import json
import re
import sys
from urllib.parse import urlparse, parse_qs
import argparse

# Constants for prompt templates from Gerrit source
HELP_ME_REVIEW_PREFIX = """You are a highly experienced code reviewer specializing in Git patches. Your
task is to analyze the provided Git patch (`patch`) and provide comprehensive
feedback. Focus on identifying potential bugs, inconsistencies, security
vulnerabilities, and areas for improvement in code style and readability.
Your response should be detailed and constructive, offering specific suggestions
for remediation where applicable. Prioritize clarity and conciseness in your
feedback.
# Step by Step Instructions
1. Read the provided `patch` carefully. Understand the changes it introduces to the codebase.
2. Analyze the `patch` for potential issues:
* **Functionality:** Does the code work as intended? Are there any bugs or unexpected behavior?
* **Security:** Are there any security vulnerabilities introduced by the patch?
* **Style:** Does the code adhere to the project's coding style guidelines? Is it readable and maintainable?
* **Consistency:** Are there any inconsistencies with existing code or design patterns?
* **Testing:** Does the patch include sufficient tests to cover the changes?
3. Formulate concise and constructive feedback for each identified issue. Provide specific suggestions for remediation where possible.
4. Summarize your findings in a clear and organized manner. Prioritize critical issues over minor ones.
5. Review the feedback written so far. Is the feedback comprehensive and sufficiently detailed?
If not, go back to step 2, focusing on any areas that require further analysis or clarification.
If yes, proceed to step 6.
6. Output the complete review.
Patch:
"""
HELP_ME_REVIEW_SUFFIX = '\n"""\nIMPORTANT NOTE: Start directly with the output, do not output any delimiters.\nTake a Deep Breath, read the instructions again, read the inputs again. Each instruction is crucial and must be executed with utmost care and attention to detail.\nReview:\n'

IMPROVE_COMMIT_MESSAGE_PREFIX = """You are a Git commit message expert, tasked with improving the quality and clarity of commit messages.
Your goal is to generate a well-structured and informative commit message based on a provided Git patch.
The commit message must adhere to a specific style guide, focusing on conciseness, clarity, and a professional tone.
You will use the patch's diff to understand the changes, summarizing complex diffs and focusing on the intent and impact of the changes.
You should paraphrase any provided bug summaries to explain the problem that was fixed.
Your output must be a single Markdown code block containing only the complete commit message (title and body),
formatted according to the provided specifications.
# Step by Step Instructions
1. **Analyze the Patch:** Carefully examine the provided `patch` to understand the changes made to the codebase.
Identify the key modifications, focusing on their intent and impact. Summarize complex changes concisely.
2. **Review Existing Commit Message:** Read the commit message included in the `patch`. Note its strengths and weaknesses.
Identify areas for improvement in clarity, conciseness, and adherence to the style guide.
3. **Refine the Title:** Craft a concise and informative commit title (under 60 characters) using sentence case and the imperative mood.
The title should accurately reflect the primary change implemented in the patch.
4. **Develop the Body:** Write a detailed body for the commit message, explaining the "what" and "why" of the changes.
Use the information gathered in Step 1 to describe the intent and impact of the modifications.
Structure the body using paragraphs, blank lines, and bullet points as needed for clarity. Wrap lines to approximately 72 characters.
5. **Ensure Style Compliance:** Verify that the commit message (title and body) adheres to all requirements outlined in the provided
"Commit Message Requirements" section. This includes checking for sentence case, imperative mood, line wrapping, and the exclusion of testing information.
6. **Format the Output:** Enclose the complete commit message (title and body) within a single Markdown code block.
Ensure there is one blank line separating the title and the body.
7. **Review and Iterate (Loop Instruction):** Review the complete commit message. Is it clear, concise, and informative?
Does it accurately reflect the changes made in the patch and adhere to the style guide? If not, return to Step 3 or Step 4 to make improvements.
If satisfied, proceed to Step 8.
8. **Output the Commit Message:** Output the final, formatted commit message as a single Markdown code block.
Patch:
"""
IMPROVE_COMMIT_MESSAGE_SUFFIX = '\n"""\nIMPORTANT NOTE: Output the commit message in the specified format.\n'


def parse_gerrit_url(url):
    """
    Parse Gerrit change URL to extract project and change_id.
    Example: https://review.gerrithub.io/c/redhat-performance/quads/+/1222441
    Returns: (project, change_id)
    """
    parsed = urlparse(url)
    path_parts = parsed.path.strip('/').split('/')
    if len(path_parts) < 4 or path_parts[0] != 'c' or path_parts[3] != '+':
        raise ValueError("Invalid Gerrit URL format")
    project = '~'.join(path_parts[1:3])  # e.g., redhat-performance~quads
    change_id = path_parts[4]
    return project, change_id


def fetch_change_detail(base_url, change_id):
    """
    Fetch change detail via Gerrit REST API to get current_revision.
    Returns: dict with change info
    """
    url = f"{base_url}/changes/{change_id}"
    headers = {'Accept': 'application/json'}
    params = {'o': ['CURRENT_REVISION']}
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    content = response.text
    # Handle Gerrit's XSSI prefix
    if content.startswith(")]}'"):
        content = content[4:]
    elif content.startswith(")]}'\n"):
        content = content[5:]
    return json.loads(content)


def fetch_commit(base_url, change_id, revision):
    """
    Fetch the commit details via Gerrit REST API to get parents.
    """
    url = f"{base_url}/changes/{change_id}/revisions/{revision}/commit"
    headers = {'Accept': 'application/json'}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    content = response.text
    # Handle Gerrit's XSSI prefix
    if content.startswith(")]}'"):
        content = content[4:]
    elif content.startswith(")]}'\n"):
        content = content[5:]
    return json.loads(content)


def fetch_patch(base_url, change_id, revision):
    """
    Fetch the unified patch via Gerrit REST API.
    """
    url = f"{base_url}/changes/{change_id}/revisions/{revision}/patch"
    headers = {'Accept': 'text/plain'}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.text


def generate_prompt(patch_content, template_key):
    """
    Generate the AI prompt by inserting the patch into the template.
    """
    if template_key == "patch_only":
        return patch_content
    elif template_key == "help_review":
        return HELP_ME_REVIEW_PREFIX + patch_content + HELP_ME_REVIEW_SUFFIX
    elif template_key == "improve_commit_message":
        return IMPROVE_COMMIT_MESSAGE_PREFIX + patch_content + IMPROVE_COMMIT_MESSAGE_SUFFIX
    else:
        raise ValueError(f"Unknown template: {template_key}")


def main(url, output_file, template_key="help_review"):
    base_url = "https://review.gerrithub.io"
    project, change_id = parse_gerrit_url(url)
    print(f"Project: {project}, Change ID: {change_id}")
    change_detail = fetch_change_detail(base_url, change_id)
    current_rev = change_detail['current_revision']
    commit = fetch_commit(base_url, change_id, current_rev)
    num_parents = len(commit.get('parents', []))
    if num_parents != 1:
        raise ValueError(f"Change has {num_parents} parents. Feature supports only single-parent changes.")
    print("Fetching patch...")
    patch_content = fetch_patch(base_url, change_id, current_rev)
    print("Generating prompt...")
    prompt = generate_prompt(patch_content, template_key)
    with open(output_file, 'w') as f:
        f.write(prompt)
    print(f"AI prompt saved to {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate AI review prompt from Gerrit change using 'Help Me Review' feature logic.")
    parser.add_argument("url", help="Gerrit change URL, e.g., https://review.gerrithub.io/c/redhat-performance/quads/+/1222441")
    parser.add_argument("-o", "--output", default="ai_prompt.txt", help="Output file (default: ai_prompt.txt)")
    parser.add_argument("-t", "--template", choices=["help_review", "improve_commit_message", "patch_only"], default="help_review", help="Prompt template (default: help_review)")
    args = parser.parse_args()
    main(args.url, args.output, args.template)
