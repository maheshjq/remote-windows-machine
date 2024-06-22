echo "# remote-windows-machine" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/maheshjq/remote-windows-machine.git
git push -u origin main

$ git config --global user.name "John Doe"
$ git config --global user.email [email protected]
Then just check to make sure the change took effect

$ git config --list
