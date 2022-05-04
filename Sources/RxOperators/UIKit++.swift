//
//  UIKit++.swift
//  TestProject
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit
import VDKit
import RxSwift
import RxCocoa

extension ObservableConvertibleType {
	
	public func asDriver() -> Driver<Element> {
		asDriver(onErrorDriveWith: .never())
	}
	
}

extension Reactive where Base: UIResponder {
	
	public var isFirstResponder: ControlProperty<Bool> {
		ControlProperty(
			values: Observable
				.merge(
					methodInvoked(#selector(UIResponder.becomeFirstResponder)),
					methodInvoked(#selector(UIResponder.resignFirstResponder))
				)
				.map { [weak view = self.base] _ in
					view?.isFirstResponder ?? false
				}
				.startWith(base.isFirstResponder)
				.distinctUntilChanged()
				.share(replay: 1),
			valueSink: AnyObserver {[weak base] in
				guard case .next(let value) = $0 else { return }
				if value {
					base?.becomeFirstResponder()
				} else {
					base?.resignFirstResponder()
				}
			}
		)
	}
	
}

extension Reactive where Base: UISearchBar {
	
	public var changes: ControlEvent<String> {
		let first = text.map { $0 ?? "" }
		let second = textDidEndEditing.map {[weak base] in base?.text ?? "" }
		let third = cancelButtonClicked.map { "" }
		return ControlEvent(events: Observable.merge(first, second, third))
	}

}

extension Reactive where Base: UIStackView {
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (V) -> AnyObserver<T>) -> Binder<[T]> {
		self.update(create: create) { value, view, _ in
			update(view).onNext(value)
		}
	}
	
}

extension Reactive where Base: UIView {
	
	public var id: Binder<String?> {
		self[keyPath: \.accessibilityIdentifier]
	}
	
}

extension ObserverType {
	
	public func animate(_ duration: TimeInterval, options: UIView.AnimationOptions = []) -> AnyObserver<Element> {
		AnyObserver { event in
			UIView.animate(duration, options: options, {
				self.on(event)
			})
		}
	}
	
}

extension Reactive where Base: UIView {
	
	public var transform: Binder<CGAffineTransform> {
		Binder(base, binding: { $0.transform = $1 })
	}
	
	public var movedToWindow: Single<Void> {
		methodInvoked(#selector(UIView.didMoveToWindow))
			.map {[weak base] _ in base?.window != nil }
			.startWith(base.window != nil)
			.filter { $0 }
			.map { _ in }
			.take(1)
			.asSingle()
	}
	
	public var isOnScreen: Observable<Bool> {
		Observable.create {[weak base] in
			Disposables.create(with: base?.observeIsOnScreen($0.onNext) ?? {})
		}
	}
	
	public var frame: Observable<CGRect> {
		Observable.create {[weak base] observer in
			Disposables.create(with: base?.observeFrame { observer.onNext($0.frame) } ?? {})
		}.distinctUntilChanged()
	}
	
	public var frameOnWindow: Observable<CGRect> {
		Observable.create {[weak base] in
			Disposables.create(with: base?.observeFrameInWindow($0.onNext) ?? {})
		}.distinctUntilChanged()
	}
	
	public var willAppear: ControlEvent<Bool> {
		let source = movedToWindow.asObservable().flatMap {[weak base] in
			base?.vc?.rx.methodInvoked(#selector(UIViewController.viewWillAppear)).map { $0.first as? Bool ?? false } ?? .empty()
		}
		return ControlEvent(events: source)
	}
	
	public var didAppear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.asObservable().flatMap {[weak base] in
			base?.vc?.rx.methodInvoked(#selector(UIViewController.viewDidAppear)).map { $0.first as? Bool ?? false } ?? .empty()
		})
	}
	
	public var willDisappear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.asObservable().flatMap {[weak base] in
			base?.vc?.rx.methodInvoked(#selector(UIViewController.viewWillDisappear)).map { $0.first as? Bool ?? false } ?? .empty()
		})
	}
	
	public var didDisappear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.asObservable().flatMap {[weak base] in
			base?.vc?.rx.methodInvoked(#selector(UIViewController.viewDidDisappear)).map { $0.first as? Bool ?? false } ?? .empty()
		})
	}
	
	public var layoutSubviews: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.layoutSubviews)).map { _ in }
		return ControlEvent(events: source)
	}
	
	public var isHidden: Observable<Bool> {
		value(at: \.isHidden)
	}
	
	public var alpha: Observable<CGFloat> {
		value(at: \.opacity).map { CGFloat($0) }
	}
	
	public var isVisible: Observable<Bool> {
		Observable.combineLatest(
			isHidden, alpha, isOnScreen, Observable.merge(willAppear.map { _ in true }, didDisappear.map { _ in false }).startWith(base.window != nil)
		)
		.map { !$0.0 && $0.1 > 0 && $0.2 && $0.3 }
		.distinctUntilChanged()
	}
	
	private func value<T: Equatable>(at keyPath: KeyPath<CALayer, T>) -> Observable<T> {
		Observable.create {[weak base] in
			guard let base = base else { return Disposables.create() }
			let observer: NSKeyValueObservation = base.layer.observe(keyPath, $0.onNext)
			base.layerObservers.observers.append(observer)
			return Disposables.create(with: observer.invalidate)
		}
	}
	
}

extension UIView {

	fileprivate var layerObservers: NSKeyValueObservations {
		let current = objc_getAssociatedObject(self, &layerObservrersKey) as? NSKeyValueObservations
		let bag = current ?? NSKeyValueObservations()
		if current == nil {
			objc_setAssociatedObject(self, &layerObservrersKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
		return bag
	}

}

private var layerObservrersKey = "layerObservrersKey0000"

extension CALayer {
	
	fileprivate func observe<T: Equatable>(_ keyPath: KeyPath<CALayer, T>, _ action: @escaping (T) -> Void) -> NSKeyValueObservation {
		observe(keyPath, options: [.new, .old, .initial]) { (layer, change) in
			guard let value = change.newValue, change.newValue != change.oldValue else { return }
			action(value)
		}
	}
	
}

private final class NSKeyValueObservations {
	var observers: [NSKeyValueObservation] = []
	
	func invalidate() {
		observers.forEach { $0.invalidate() }
	}
}
extension Binder where Value == CGAffineTransform {
	
	public func scale() -> AnyObserver<CGFloat> {
		mapObserver { CGAffineTransform(scaleX: $0, y: $0) }
	}
	
	public func scale() -> AnyObserver<CGSize> {
		mapObserver { CGAffineTransform(scaleX: $0.width, y: $0.height) }
	}
	
	public func rotation() -> AnyObserver<CGFloat> {
		mapObserver { CGAffineTransform(rotationAngle: $0) }
	}
	
	public func translation() -> AnyObserver<CGPoint> {
		mapObserver { CGAffineTransform(translationX: $0.x, y: $0.y) }
	}
	
}
