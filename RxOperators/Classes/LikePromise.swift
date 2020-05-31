//
//  LikePromise.swift
//  TestPr
//
//  Created by Daniil on 21.02.2020.
//  Copyright © 2020 crypto_user. All rights reserved.
//

import RxSwift

extension ObservableConvertibleType {
    
    public func then(on queue: DispatchQueue? = nil, _ action: @escaping (Element) throws -> ()) -> Observable<Element> {
        asObservable().do(onNext: action)
    }
    
    public func `catch`(on queue: DispatchQueue? = nil, _ action: @escaping (Error) throws -> ()) -> Observable<Element> {
        asObservable().do(onError: action)
    }
    
}

@dynamicMemberLookup
public final class PromiseSubject<Element>: ObservableType {
    private var array: Stack<Element>
    private let source: Observable<Element>
    private let publish = PublishSubject<Element>()
    public var values: [Element] { array.asArray }
    public var last: Element? { array[array.count - 1] }
    private(set) public var isCompleted = false
    private(set) public var error: Error?
    
    public init(_ observable: Observable<Element>, maxCount: Int = 1) {
        source = observable
        array = Stack(maxCount)
    }
    
    private init(_ observable: Observable<Element>, array: Stack<Element>) {
        source = observable
        self.array = array
    }
    
    public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
        let subject = PublishSubject<Element>()
        var result = subject.subscribe(observer)
        array.forEach(subject.onNext)
        if isCompleted {
            subject.onCompleted()
        } else if let err = error {
            subject.onError(err)
        } else {
            result = Disposables.create(result, publish.subscribe(subject))
        }
        return result
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> PromiseSubject<T> {
        let result = PromiseSubject<T>(source.map({ $0[keyPath: keyPath] }), array: array.map(keyPath))
        result.isCompleted = isCompleted
        result.error = error
        return result
    }
    
}

struct Stack<Element>: Collection, CustomStringConvertible {
    let startIndex = 0
    var endIndex: Int { array.endIndex }
    var count: Int { array.count }
    var description: String { array.description }
    private var offset = 0
    private var array: [Element] = []
    private let maxCount: Int
    public var limit: Int {
        get { maxCount }
        set { self = Stack(Array(asArray.prefix(newValue)), max: newValue) }
    }
    
    init(_ count: Int) {
        maxCount = Swift.max(1, count)
    }
    
    init(_ array: [Element]) {
        maxCount = array.count
        self.array = array
    }
    
    private init(_ array: [Element], max count: Int) {
        maxCount = count
        self.array = array
    }
    
    func index(after i: Int) -> Int { array.index(after: i) }
    
    subscript(position: Int) -> Element {
        get { array[realIndex(for: position)] }
        set { array[realIndex(for: position)] = newValue }
    }
    
    mutating func append(_ newElement: Element) {
        guard array.count == maxCount else {
            array.append(newElement)
            return
        }
        array[offset] = newElement
        offset = (offset + 1) % maxCount
    }
    
    private func realIndex(for index: Int) -> Int {
        guard offset > 0 else { return index % maxCount }
        return (offset + index) % maxCount
    }
    
    var asArray: [Element] {
        guard offset > 0 else { return array }
        let prefix = array.prefix(offset)
        let suffix = array.suffix(count - offset)
        return Array(suffix + prefix)
    }
    
    func map<T>(_ keyPath: KeyPath<Element, T>) -> Stack<T> {
        var result = Stack<T>(maxCount)
        result.array = array.map({ $0[keyPath: keyPath] })
        result.offset = offset
        return result
    }
    
}
