import tfc
import json


def get_vars_from_workspace(workspace):
    client = tfc.TerraformClient(
        token='yMq2qhAuq3FvWA.atlasv1.yNPrbFzy6mdvBfO0dguYTavVvVUpvOHj1GIf8yZuIlirmCGhP1PGdRPVxG3uQqc8Sy8',
        organization='merce_chan_demo',
        workspace=workspace)

    variables = client.get_variables()

    for key, value in variables.items():
        print(key)
        print('\t', '->', value.id)
        print('\t', '->', value.name)
        print('\t', '->', value.value)


def create_terraform_cloud_run(workspace, run_name):
    client = tfc.TerraformClient(
        token='yMq2qhAuq3FvWA.atlasv1.yNPrbFzy6mdvBfO0dguYTavVvVUpvOHj1GIf8yZuIlirmCGhP1PGdRPVxG3uQqc8Sy8',
        organization='merce_chan_demo',
        workspace=workspace)

    terraform_run = client.create_run(run_name)
    print(terraform_run.id)
    print(terraform_run.url)


if __name__ == '__main__':
    work_space = 'terraform_cloud_azure_demo'
    # get_vars_from_workspace(work_space)
    create_terraform_cloud_run(work_space, 'azure_first_run')
