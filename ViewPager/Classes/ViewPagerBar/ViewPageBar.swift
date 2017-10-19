//
//  ViewPageBar.swift
//  Pods
//
//  Created by Jack on 2017/7/2.
//
//


import UIKit
import SnapKit

// MARK:- ViewPageBarDelegate
protocol ViewPageBarDelegate : class {
    
    func viewPageBar(_ viewPageBar : ViewPageBar, selectedIndex index : Int)
    
}

public class ViewPageBar: UIView {
    
    weak var delegate : ViewPageBarDelegate?
    
    fileprivate var titles : [String]!
    var style : StyleCustomizable!
    
    var collectionView: UICollectionView!
    
    var currentIndex : Int = 0
    var bottomoffset: CGFloat = 5
    
    
    fileprivate lazy var bottomLine : UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = self.style.bottomLineColor
        return bottomLine
    }()
    
    fileprivate lazy var normalColor : (r : CGFloat, g : CGFloat, b : CGFloat) = self.rgb(self.style.normalColor)
    
    fileprivate lazy var selectedColor : (r : CGFloat, g : CGFloat, b : CGFloat) = self.rgb(self.style.selectedColor)
    
    init(frame: CGRect, titles : [String], style : StyleCustomizable) {
        super.init(frame: frame)
        
        self.titles = titles
        self.style = style
        setupCollectionView()
        self.clipsToBounds = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewWillLayoutSubviews() {
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func viewDidLayoutSubviews() {
        let indexPath = IndexPath(item: self.currentIndex, section: 0)
        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        self.collectionView(self.collectionView, didSelectItemAt: indexPath)
    }
    
}



// MARK: - randering ui
extension ViewPageBar {
    
    fileprivate func setupCollectionView() {
        backgroundColor = style.titleBgColor
        let layout = ViewPageBarLayout(self)
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        collectionView.register(PageBarItem.self, forCellWithReuseIdentifier: PageBarItem.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        layout.minimumLineSpacing =  style.titleMargin
        layout.minimumInteritemSpacing =  style.titleMargin
        collectionView.contentInset = UIEdgeInsets(top: 0, left: style.isSplit == true ? style.titleMargin : 0, bottom: 0, right:  style.isSplit == true ? -style.titleMargin : 0)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    func setupBottomLine() {
        self.collectionView.addSubview(bottomLine)
        guard let cell = self.collectionView(self.collectionView, cellForItemAt: IndexPath(item: 0, section: 0)) as? PageBarItem else {
            return
        }
        cell.titleLabel.textColor = style.selectedColor
        self.bottomLine.frame = CGRect(x: (cell.frame.width - style.bottomLineW) / 2, y: cell.frame.height - style.bottomLineH - style.bottomLineOffset, width: style.bottomLineW, height: style.bottomLineH)
    }
    
    func frmaeOfCellAt(_ index: Int) -> CGRect {
        let layoutAttributes: UICollectionViewLayoutAttributes? = self.collectionView?.layoutAttributesForItem(at: IndexPath(item: index, section: 0))
        return layoutAttributes?.frame ?? .zero
    }
    
    func delay(after: TimeInterval, execute: @escaping () -> Void) {
        let delayTime = DispatchTime.now() + after
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            execute()
        }
    }


}

extension ViewPageBar: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageBarItem.reuseIdentifier, for: indexPath) as? PageBarItem else {
            fatalError("not found the right cell")
        }
        cell.titleLabel.font = style.font
        cell.titleLabel.text = titles[indexPath.item]
        cell.backgroundColor = .brown
        return cell
    }
}

extension ViewPageBar: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.viewPageBar(self, selectedIndex: indexPath.item)
        let fromCell: PageBarItem? = collectionView.cellForItem(at: IndexPath(item: self.currentIndex, section: 0)) as? PageBarItem
        
        fromCell?.titleLabel.textColor = style.normalColor
        guard let toCell: PageBarItem = collectionView.cellForItem(at: indexPath) as? PageBarItem else {
            return
        }
        toCell.titleLabel.textColor = style.selectedColor
        UIView.animate(withDuration: 0.25) {
                self.bottomLine.center = CGPoint(x: toCell.center.x, y: self.bottomLine.center.y)
        }
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.currentIndex = indexPath.item
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selectedCell: PageBarItem? = collectionView.cellForItem(at: indexPath) as? PageBarItem
        selectedCell?.titleLabel.textColor = style.normalColor
    }
    
}

extension ViewPageBar: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGSize = (self.titles[indexPath.item] as NSString).size(withAttributes: [NSAttributedStringKey.font: style.font])
        if style.isSplit == true {
            return CGSize(width: (collectionView.bounds.width - (style.titleMargin * CGFloat(self.titles.count + 1))) / CGFloat(self.titles.count), height: collectionView.bounds.height)
        }
        if style.titleWidth != 0 {
            return CGSize(width: style.titleWidth, height: self.frame.height)
        }
        return CGSize(width: size.width + 8, height: self.frame.height)
    }
}

extension ViewPageBar {
    
    func finished(_ fromIndex: Int, toIndex: Int) {
        
    }
    
    func updateProgress(_ progress : CGFloat, fromIndex : Int, toIndex : Int) {
        
        guard let sourceItem = self.collectionView.cellForItem(at: IndexPath(item: fromIndex, section: 0)) as? PageBarItem else {
            return
        }
        guard let targetItem = self.collectionView.cellForItem(at: IndexPath(item: toIndex, section: 0)) as? PageBarItem else {
            return
        }
        let colorDelta = (selectedColor.0 - normalColor.0, selectedColor.1 - normalColor.1, selectedColor.2 - normalColor.2)

        sourceItem.titleLabel.textColor = UIColor(r: selectedColor.0 - colorDelta.0 * progress, g: selectedColor.1 - colorDelta.1 * progress, b: selectedColor.2 - colorDelta.2 * progress)
        targetItem.titleLabel.textColor = UIColor(r: normalColor.0 + colorDelta.0 * progress, g: normalColor.1 + colorDelta.1 * progress, b: normalColor.2 + colorDelta.2 * progress)

        currentIndex = toIndex
        let bottomLineFromCenterX = sourceItem.frame.origin.x
        let marginWidth: CGFloat = abs(targetItem.center.x - sourceItem.center.x)
        let progressWidth: CGFloat = progress * (targetItem.frame.width + style.titleMargin)
        let bottomLineToCenterX =  toIndex > fromIndex ? bottomLineFromCenterX + progressWidth : bottomLineFromCenterX - progressWidth
        if style.isAnimateWithProgress {
            self.bottomLine.center = CGPoint(x: bottomLineToCenterX, y: self.bottomLine.center.y)
        } else if progressWidth * 2 > marginWidth {
            UIView.animate(withDuration: 0.25) {
                self.bottomLine.center = CGPoint(x: targetItem.center.x, y: self.bottomLine.center.y)
            }
        }
        self.collectionView.scrollToItem(at: IndexPath(item: toIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK:- get the cgfloat of the color
extension ViewPageBar {
    
    fileprivate func rgb(_ color : UIColor) -> (CGFloat, CGFloat, CGFloat) {
        return (color.components[0] * 255, color.components[1] * 255, color.components[2] * 255)
    }

}

