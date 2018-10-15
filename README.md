# swift-stm

[![Twitter: @lbrndnr](https://img.shields.io/badge/contact-@lbrndnr-blue.svg?style=flat)](https://twitter.com/lbrndnr)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/lbrndnr/ImagePickerSheetController/blob/master/LICENSE)

## About
swift-stm is an optimistic and lock free [software transactional memory](https://en.wikipedia.org/wiki/Software_transactional_memory) written in Swift. It's very rudimental and really only a draft as of now. I wouldn't be using it in production could if I were you. Feel free to try it out though :)

## What does it do exactly?

An STM allows you to write thread safe code by making blocks of code seem to be executed atomically. This means that the transaction is either executed in a given point in time or not at all. In reality, however, it just executes the transaction and notices potential collisions. 
The idea behind this is that in real life, collisions are rare and locks a bit of an overhead. This means that (technically) STMs are a lot easier to use (no deadlocks, better performance yada yada) than traditional locks.
Note that this is just a draft, I can't guarantee mutex nor performance!

## So how do I use it?

So instead of using Dispatch...

```swift
func transfer(from: Account, to: Account, amount: Int) -> Bool {
    var res = false
    
    queue.async {            
        let i = from.balance
        
        guard i >= amount else {
            return
        }
        
        from.balance = i - amount
       	to.balance = to.balance + amount
        
        res = true
    }
    
   return res
}
```

... you'd write something like this

```swift
func transfer(from: Account, to: Account, amount: Int) -> Bool {
    var res = false
    
    atomic {            
        let i = try from.balance.get()
        
        guard i >= amount else {
            return
        }
        
        try from.balance.set(i - amount)
        try to.balance.set(to.balance.get() + amount)
        
        res = true
    }
    
    return res
}
```

I must admit that the syntax is a bit clumsy as of now...

## Installation

```
github "lbrndnr/swift-stm"
```

## Author
I'm Laurin Brandner, I'm on [Twitter](https://twitter.com/lbrndnr).

## License
swift-stm is licensed under the [MIT License](http://opensource.org/licenses/mit-license.php).
