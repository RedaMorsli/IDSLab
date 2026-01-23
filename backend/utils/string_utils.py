import re

def to_snake_case(name):
    # Add an underscore before each uppercase letter that is followed by a lowercase letter
    name = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', name)
    # Add an underscore before each lowercase letter or digit that is preceded by an uppercase letter
    name = re.sub(r'([a-z\d])([A-Z])', r'\1_\2', name)
    # Replace any hyphens or spaces with underscores
    name = re.sub(r'[-\s]+', '_', name)
    # Convert the entire string to lowercase
    return name.lower()


def to_snake_case_dash(name):
    # Add an underscore before each uppercase letter that is followed by a lowercase letter
    name = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1-\2', name)
    # Add an underscore before each lowercase letter or digit that is preceded by an uppercase letter
    name = re.sub(r'([a-z\d])([A-Z])', r'\1-\2', name)
    # Replace any hyphens or spaces with underscores
    name = re.sub(r'[-\s]+', '-', name)
    # Convert the entire string to lowercase
    return name.lower()
