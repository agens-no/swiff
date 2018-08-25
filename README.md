# swiff

<img alt="" src="https://user-images.githubusercontent.com/3652587/43640738-5563b6f2-9721-11e8-97a4-4a2566b4290e.png">

Why not let the computer do all that diffing of timestamps you tend to do manually?

## 👋 Usage

### Live with any command
```sh
command | swiff
```

Try it out
```sh
while true; do echo "Foo"; sleep $[ ($RANDOM % 3) + 1 ]s; done | swiff
```

### With [fastlane](https://github.com/fastlane/fastlane)
```sh
fastlane build | swiff --fastlane
```

Or even shorter
```sh
fastlane build | swiff -f
```

Or maybe you have an old build log from fastlane?
```sh
cat build.log | swiff -f
```

## 🤲 Example output

### Summary
Useful summary at the end with most important highlights

<img width="822" src="https://user-images.githubusercontent.com/3652587/43637715-4fe3df82-9716-11e8-9a75-ec43400024fb.png">


## ✌️ Install

### Globally by oneliner
```sh
git clone git@github.com:agens-no/swiff.git && cd swiff && make && cd .. && rm -rf swiff/
```

You may now type `swiff help` from any directory in terminal to verify that the install is complete

<details>
<summary>What is the onliner doing?</summary>
  
1. Uses git to clone `swiff` to a directory `swiff` in your current directory
2. moves in to the created `swiff` folder
3. builds swift using the Makefile (basically compiling main.swift and installing `swiff` at `/usr/local/bin/swiff`)
4. moves back out of the folder
5. deletes the `swiff` folder

</details>

### Globally by cloning
```sh
git clone git@github.com:agens-no/swiff.git
cd swiff
make
```

You may now type `swiff help` from any directory in terminal to verify that the install is complete

### Locally by onliner

```sh
curl --fail https://raw.githubusercontent.com/agens-no/swiff/master/main.swift > swiff.swift && swiftc -o swiff swiff.swift && rm swiff.swift
```

You may now type `./swiff help` from your current directory and use it like `fastlane build | ./swiff -f`

<details>
<summary>What is the onliner doing?</summary>
  
1. Uses curl to copy `main.swift` to a file called `swiff.swift` in your current directory
2. builds using your current swift tooling
3. deletes swiff.swift

</details>

### Installation issues?

Might be because of requirements: Swift 4, Xcode, macOS

Open an issue and let me know!

## ✊ Advanced usage

```
Usage: swiff [-l low] [-m medium] [-h high] [-r reset-mark] [-d diff-mode] [-s summary-limit] [-f --fastlane]
  -l, --low                   Threshold in seconds for low duration color formatting (default: 1)
  -m, --medium                Threshold in seconds for medium duration color formatting (default: 5)
  -h, --high                  Threshold in seconds for high duration color formatting (default: 10)
  -r, --reset-mark            String match to reset total counter (default: none)
  -d, --diff-mode             Valid options is "live" or "fastlane (default: live)
  -s, --summary-limit         Maximum number of lines in summary (default: 20)

  -f, --fastlane              Shortcut for --diff-mode fastlane --reset-mark "Step :"

Example: cat build.log | swiff --low 1 --medium 5 --high 10 --reset-mark "Step: " --diff-mode live --summary-limit 20

Example: fastlane build | swiff -f
```

## 🤙 License

MIT
