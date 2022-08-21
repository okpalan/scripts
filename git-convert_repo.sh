#!/bin/bash
###########
# ./convert_repo.sh
# Author: Igor Serko <igor.serko@gmail.com>
# Description: Allows the user to join multiple git repositories under one single repository
# Procedure: Using git filter-branch we rewrite the history of every repo
# example of current tree
#     -- REPOONE
#      |-- repoone files
#     -- REPOTWO
#      |-- repotwo files
#     -- REPOTHREE
#      |-- repothree files
# after version rewrite
#     -- REPOONE
#      |-- REPOONE
#        |-- repoone files
#     -- REPOTWO
#      |-- REPOTWO
#        |-- repotwo files
#     -- REPOTHREE
#      |-- REPOTHREE
#        |-- repothree files
# ** Warning: if you have a folder named the same as the REPONAME inside the root of the repo then you will have problems **
# ** Warning: branches that you would want to move along should appear only in one project. When creating **
# **          the new tree the script takes the branch out of one projects and fills in the branch with **
# **          master branches from all the other projects **

##########
MAIN_TREE_NAME=yourproject                 # this will be the folder in which your joined git repository will be created
REPO_DIR=repos                             # this is the folder that will hold all the retrieved repositories
GITHUB_PATH="git@github.com:/account"      # Address to your github account
REPOS="repoone repotwo repothree"          # Names of the repositories you want to join
BRANCHES="branchone branchtwo branchthree" # Names of branches that you want to join

if [ -d $MAIN_TREE_NAME ]
then
    echo "directory $MAIN_TREE_NAME already exists. Exiting."
    exit
fi

if [ -d $REPO_DIR ]
then
    echo "directory $REPO_DIR already exists. Exiting."
    exit
fi

# Create the main tree directory
mkdir $MAIN_TREE_NAME
cd $MAIN_TREE_NAME
git init
cd ..

# Create the repo directory and move into it
mkdir $REPO_DIR
cd $REPO_DIR

run_filter_branch () {
    git filter-branch -f --index-filter "git ls-files -s | sed \"s-\\t-&$1/-\" | GIT_INDEX_FILE=\$GIT_INDEX_FILE.new git update-index --index-info && mv \$GIT_INDEX_FILE.new \$GIT_INDEX_FILE" HEAD
}

# Loop through all repositories, clone them and run filter-branch on all of them,
# then pull their master branches into the main tree
for repo in $REPOS
do
    git clone $GITHUB_PATH/$repo.git
    cd $repo
    echo "=== Running filter branch on repo $repo / branch master ==="
    run_filter_branch $repo
    cd ../../$MAIN_TREE_NAME
    git pull ../$REPO_DIR/$repo master
    cd ../$REPO_DIR
done

# Loop through all repositories and scan their branch list for the branches you specified
# Then checkout that branch, run filter-branch on it pull it into a temporary repository
# Then pull the master branches of all the other repositories into it, move to the main tree,
# add the temporary repository as a remote, fetch it, checkout the branch then remove the remote
for repo in $REPOS
do
    echo
    echo "===== Processing project $repo ====="
    cd $repo
    CBRAN=`git branch -a`
    cd ..
    for br in $CBRAN
    do
        for bran in $BRANCHES
        do
            if [ "$br" = "remotes/origin/$bran" ]
            then
                cd $repo
                echo
                echo "=== Checking out branch $bran ==="
                git checkout $bran
                echo "=== Running filter branch on repo $repo / branch $bran ==="
                run_filter_branch $repo
                cd ../..
                rm -rf branc
                echo "=== Creating a new folder for the branch ==="
                mkdir branc
                cd branc
                git init
                git pull ../$REPO_DIR/$repo $bran
                git checkout -b $bran
                for proj in $REPOS
                do
                    if [ "$proj" != "$repo" ]
                    then
                        git pull ../$REPO_DIR/$proj master 
                    fi
                done
                cd ../$MAIN_TREE_NAME
                echo "=== Adding branch to main tree ==="
                git remote add exbr ../branc
                git fetch exbr
                git checkout $bran
                git remote rm exbr
                git checkout master
                cd ..
                rm -rf branc
                cd repos
            fi
        done 
    done
done
# additonal steps:
# Remove the repo directory
cd ..
rm -rf $REPO_DIR

echo "=== The joined git repository has been created ==="
echo "=== and is located in the $MAIN_TREE_NAME folder ==="
