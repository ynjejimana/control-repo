# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

## Ensure your git is configured properly

    git config --global user.email "your_email@example.com"
    git config --global user.name "Your Name"

Also if you are not familiar with git then here are some good resource to help get your started:

* [Atlassian Learn Git](https://www.atlassian.com/git/tutorials/what-is-version-control)
* [Git Website](https://git-scm.com/)
* [Axosoft Gitflow](https://blog.axosoft.com/gitflow/)

## Pull Request Process

This repository uses the GitFlow process for pull requests more info can be found [here](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).

Process can be followed as such:

###### Adding a new feature
1. Check out the development branch <code>git checkout development</code>;
2. Create new feature branch <code>git checkout -b feature/new_feature development</code>;
3. Once your feature is ready commit and push <code>git push origin feature/new_feature</code>;
4. Create a pull request in gitlab to development branch.

###### Preparing a new release
1. Check out the development branch and ensure it is up to date;


      git checkout development
      git pull
2. Create new release branch <code>git checkout -b release/x.x development</code>;
3. Add any last minute changes into this branch;
4. Once ready push to gitlab <code>git push origin release/x.x</code>;
5. After review merge this branch into both development and master.

###### Applying a hotfix

1. Checkout the master branch and ensure it is up to date;


    git checkout master
    git pull
2. Create new hotfix branch <code>git checkout -b hotfix/hotfix_name master</code>;
3. Apply hot fix and then commit and push to gitlab <code>git push origin hotfix/hotfix_name</code>;
4. After review merge this branch into both development and master.
