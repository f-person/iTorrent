//
//  TorrentsListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit
import Bond

class TorrentListController: MvvmViewController<TorrentListViewModel> {
    @IBOutlet var tableView: ThemedUITableView!

    @IBOutlet var tableviewPlaceholder: UIView!
    @IBOutlet var tableviewPlaceholderImage: UIImageView!
    @IBOutlet var tableviewPlaceholderText: UILabel!

    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var rssButton: UIBarButtonItem!

    @IBOutlet weak var addTorrentButton: UIBarButtonItem!
    @IBOutlet weak var sortButton: UIBarButtonItem!

    var initialBarButtonItems: [UIBarButtonItem] = []
    var editmodeBarButtonItems: [UIBarButtonItem] = []

    var searchController: UISearchController!

    var torrentListDataSource: TorrentListDataSource!
    var rssSearchDataSource: RssSearchDataSource!

    override var toolBarIsHidden: Bool? {
        false
    }

    func localize() {
        tableviewPlaceholderText.text = Localize.get("MainController.Table.Placeholder.Text")
    }

    func showUpdateLog() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            if let updateDialog = Dialog.createUpdateLogs() {
                self.present(updateDialog, animated: true)
            }
        }
    }

    override func themeUpdate() {
        super.themeUpdate()

        let theme = Themes.current
        view.backgroundColor = theme.backgroundMain
        tableView.backgroundColor = theme.backgroundMain
        tableviewPlaceholderImage.tintColor = theme.secondaryText
        searchbarUpdateTheme(theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 14.0, *) {
            addTorrentButton.menu = createMenu()
            setupSortButtonMenu()
        } else {
            addTorrentButton.target = self
            addTorrentButton.action = #selector(addTorrent(_:))

            sortButton.target = self
            sortButton.action = #selector(sortAction(_:))
        }
    }

    override func setupViews() {
        localize()

        initializeTableView()
        initializeSearchView()
        initializeEditMode()
        showUpdateLog()

        themeUpdate()
    }

    override func binding() {
        /// TableView Binding
        viewModel.tableViewData.observeNext { torrents in
            var snapshot = DataSnapshot<String, TorrentModel>()
            snapshot.appendSections(torrents.collection.map {
                $0.title
            })
            torrents.collection.forEach {
                snapshot.appendItems($0.items, toSection: $0.title)
            }
            self.torrentListDataSource.apply(snapshot)
            self.tableView.visibleCells.forEach {
                ($0 as! UpdatableModel).updateModel()
            }
        }.dispose(in: bag)

        /// Binding Loading Indicator
        viewModel.loadingIndicatiorHidden.observeNext { [weak self] hidden in
            if hidden {
                self?.loadingIndicator.stopAnimating()
            } else {
                self?.loadingIndicator.startAnimating()
            }
        }.dispose(in: bag)

        /// Binding RSS Indicator
        RssFeedProvider.shared.rssModels.observeNext { [weak self] models in
            let updates = models.collection.contains(where: { !$0.muteNotifications.value && $0.updatesCount > 0 })
            self?.rssButton.image = UIImage(named: updates ? "RssNews" : "Rss")
        }.dispose(in: bag)

        /// Binding TableView Placeholder
        viewModel.tableviewPlaceholderHidden.bind(to: tableviewPlaceholder.reactive.isHidden).dispose(in: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if splitViewController?.isCollapsed ?? true {
            smoothlyDeselectRows(in: tableView)
        }
    }

    @IBAction func editAction(_ sender: UIBarButtonItem) {
        triggerEditMode()
    }

    @IBAction func preferencesAction(_ sender: UIBarButtonItem) {
        if #available(iOS 11, *) {
        } else {
            let back = UIBarButtonItem()
            back.title = title
            navigationItem.backBarButtonItem = back
        }
        show(PreferencesController(), sender: self)
    }

    @IBAction func rssAction(_ sender: UIBarButtonItem) {
        if #available(iOS 11, *) {
        } else {
            let back = UIBarButtonItem()
            back.title = title
            navigationItem.backBarButtonItem = back
        }
        show(RssFeedController(), sender: self)
    }

    @objc func sortAction(_ sender: UIBarButtonItem) {
        let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
            self.viewModel.update()
            self.updateScrollInset()
        })
        present(sortingController, animated: true)
    }

    @available(iOS 14.0, *)
    func setupSortButtonMenu() {
        sortButton.menu = SortingManager.createSortingMenu(applyChanges: {
            self.viewModel.update()
            self.updateScrollInset()
            self.setupSortButtonMenu()
        })
    }
}
 
