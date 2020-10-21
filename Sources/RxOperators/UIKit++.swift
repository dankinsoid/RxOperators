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
		self[\.accessibilityIdentifier]
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
