//
//  ViewController.swift
//  Chat
//
//  Created by Jun Tanaka on 2017/03/28.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import UIKit
import Tuka
import ReactiveSwift
import Result

final class ViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var sendButton: UIButton?

    let session = Session()
    let records = MutableProperty<[String]>([])

    var viewBindingDisposable: Disposable?
    var messageObservingDisposable: Disposable?

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

        let disposable = CompositeDisposable()

        disposable += records.signal.observeValues { [weak self] records in
            self?.collectionView?.reloadData()
        }

        disposable += NotificationCenter.default.reactive.notifications(forName: .UIKeyboardWillShow).observeValues { notification in
            // Todo: adjust text field position
        }

        disposable += NotificationCenter.default.reactive.notifications(forName: .UIKeyboardDidHide).observeValues { notification in
            // Todo: adjust text field position
        }

        viewBindingDisposable = ScopedDisposable(disposable)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let collectionView = self.collectionView {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = CGSize(width: collectionView.bounds.width, height: 44)
        }
    }

    func insertRecord(text: String) {
        records.modify { value in
            value.insert(text, at: 0)
        }
    }

    func startObservingMessages() {
        let disposable = CompositeDisposable()

        disposable += session.incomingMessages(forName: .join).observeValues { [weak self] _, peer in
            self?.insertRecord(text: peer.displayName + " joined.")
        }

        disposable += session.incomingMessages(forName: .leave).observeValues { [weak self] _, peer in
            self?.insertRecord(text: peer.displayName + " leaved.")
        }

        disposable += session.incomingMessages(of: PostMessage.self).observeValues { [weak self] message, peer in
            self?.insertRecord(text: peer.displayName + ": " + message.text)
        }

        messageObservingDisposable = ScopedDisposable(disposable)
    }

    func stopObservingMessages() {
        messageObservingDisposable?.dispose()
        messageObservingDisposable = nil
    }

    @IBAction func send(_ sender: UIControl) {
        guard let text = textField?.text else {
            return
        }

        let peers = session.connectedPeers.value

        if peers.count > 0 {
            do {
                let message = PostMessage(text: text)
                try session.send(message, to: Set(session.connectedPeers.value))
            } catch {
                print("Failed to send post message with error: \(error)")
            }
        }

        insertRecord(text: "Me: " + text)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        send(textField)
        textField.text = nil
        return false
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return records.value.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.label?.text = records.value[indexPath.row]
        return cell
    }
}
