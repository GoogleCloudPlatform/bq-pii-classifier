

def read_file(path: str):
    with open(path, "r") as file:
        return file.read()


def replace_template_variables(vars : dict, file_path : str) -> str:
    # Read the file content
    content = read_file(file_path)
    
    # Replace template variables with their values
    for key, value in vars.items():
        content = content.replace(f'${{{key}}}', value)

    return content