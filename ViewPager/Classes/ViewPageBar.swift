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
    fileprivate var style : StyleCustomizable!
    var currentIndex : Int = 0
    var bottomoffset: CGFloat = 5
    
    fileprivate lazy var titleLabels : [UILabel] = [UILabel]()
    
    fileprivate lazy var bottomLine : UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = self.style.bottomLineColor
        return bottomLine
    }()
    
    fileprivate lazy var normalColor: (r: CGFloat, g: CGFloat, b: CGFloat) = self.rgb(self.style.normalColor)
    
    fileprivate lazy var selectedColor: (r: CGFloat, g: CGFloat, b: CGFloat) = self.rgb(self.style.selectedColor)
    
    init(frame: CGRect, titles: [String], style: StyleCustomizable) {
        super.init(frame: frame)
        
        self.titles = titles
        self.style = style
        setupUI()
        self.clipsToBounds = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



// MARK: - randering ui
extension ViewPageBar {
    fileprivate func setupUI() {
        backgroundColor = style.titleBgColor
        setupTitleLabels()
        
        setupTitleLabelsPosition()
        
        if style.isShowBottomLine {
            setupBottomLine()
        }
    }
    
    fileprivate func setupTitleLabels() {
        for (index, title) in titles.enumerated() {
            let label = UILabel()
            label.tag = index
            label.text = title
            label.textColor = index == 0 ? style.selectedColor : style.normalColor
            label.font = style.font
            label.textAlignment = .center
            
            label.isUserInteractionEnabled = true
            let tapGes = UITapGestureRecognizer(target: self, action: #selector(titleLabelClick(_ :)))
            label.addGestureRecognizer(tapGes)
            titleLabels.append(label)
            addSubview(label)
        }
    }
    
    
    fileprivate func setupTitleLabelsPosition() {
        
        let count = titles.count
        if count <= 5 {
            for (index, label) in titleLabels.enumerated() {
                if index == 0 {
                    label.snp.makeConstraints({ (make) in
                    make.left.equalTo(self.snp.left).offset(style.titleMargin)
                    make.top.equalTo(self.snp.top)
                    make.height.equalTo(self.snp.height).offset(-4)
                    })
                } else if index == count - 1 {
                    label.snp.makeConstraints({ (make) in
                    make.top.height.width.equalTo(titleLabels[index - 1])
                    make.right.equalTo(self.snp.right).offset(-style.titleMargin)
                    make.left.equalTo(titleLabels[index - 1].snp.right).offset(style.titleMargin)
                    make.width.equalTo(titleLabels[index - 1].snp.width)
                    })
                } else {
                    label.snp.makeConstraints({ (make) in
                        make.top.height.equalTo(titleLabels[index - 1])
                        make.width.equalTo(titleLabels[index - 1].snp.width)
                        make.left.equalTo(titleLabels[index - 1].snp.right).offset(style.titleMargin)
                    })
                }
            }
        }
    }
    
    fileprivate func setupBottomLine() {
        guard let firstTitleLabel = titleLabels.first else {
            return
        }
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.centerX.equalTo(firstTitleLabel.snp.centerX)
            make.width.equalTo(firstTitleLabel.snp.width)
                .offset(-self.style.bottomLineMargin)
            make.top.equalTo(firstTitleLabel.snp.bottom)
                .offset(-bottomoffset)
            make.height.equalTo(style.bottomLineH)
        }
    }
}


extension ViewPageBar {
    
    @objc fileprivate func titleLabelClick(_ tap : UITapGestureRecognizer) {
        guard let currentLabel = tap.view as? UILabel else { return }
        if currentLabel.tag == currentIndex { return }
        let oldLabel = titleLabels[currentIndex]
        currentLabel.textColor = style.selectedColor
        oldLabel.textColor = style.normalColor
        currentIndex = currentLabel.tag
        delegate?.viewPageBar(self, selectedIndex: currentIndex)
        
        if style.isShowBottomLine {
            UIView.animate(withDuration: 0.15, animations: {
                self.bottomLine.snp.remakeConstraints({ (make) in
                    make.centerX.equalTo(currentLabel.snp.centerX)
                    make.width.equalTo(currentLabel.snp.width)
                        .offset(-self.style.bottomLineMargin)
                    make.top.equalTo(currentLabel.snp.bottom)
                        .offset(-self.bottomoffset)
                    make.height.equalTo(self.style.bottomLineH)
                })
                self.layoutIfNeeded()
            })
        }
    }
}

extension ViewPageBar {
    
    func finishProgress(index: Int) {
        let currentLabel = self.titleLabels[index]
        if style.isShowBottomLine {
            UIView.animate(withDuration: 0.15, animations: {
                self.bottomLine.snp.remakeConstraints({ (make) in
                    make.centerX.equalTo(currentLabel.snp.centerX)
                    make.width.equalTo(currentLabel.snp.width)
                        .offset(-self.style.bottomLineMargin)
                    make.top.equalTo(currentLabel.snp.bottom)
                        .offset(-self.bottomoffset)
                    make.height.equalTo(self.style.bottomLineH)
                })
                self.layoutIfNeeded()
            })
        }
        currentLabel.textColor = style.selectedColor
        self.titleLabels.filter({$0 != currentLabel})
            .forEach { $0.textColor = style.normalColor }
    }
    
    func updateProgress(_ progress : CGFloat, fromIndex : Int, toIndex : Int) {

        let sourceLabel = titleLabels[fromIndex]
        let targetLabel = titleLabels[toIndex]
        let colorDelta = (selectedColor.0 - normalColor.0, selectedColor.1 - normalColor.1, selectedColor.2 - normalColor.2)

        sourceLabel.textColor = UIColor(r: selectedColor.0 - colorDelta.0 * progress, g: selectedColor.1 - colorDelta.1 * progress, b: selectedColor.2 - colorDelta.2 * progress)

        targetLabel.textColor = UIColor(r: normalColor.0 + colorDelta.0 * progress, g: normalColor.1 + colorDelta.1 * progress, b: normalColor.2 + colorDelta.2 * progress)

        currentIndex = toIndex
        let bottomLineFromCenterX = sourceLabel.center.x
        let bottomLineToCenterX = toIndex > fromIndex ? bottomLineFromCenterX + progress * targetLabel.frame.size.width : bottomLineFromCenterX - progress * targetLabel.frame.size.width
        if style.isShowBottomLine {
            UIView.animate(withDuration: 0.15, animations: {
                self.bottomLine.snp.remakeConstraints({ (make) in
                    make.centerX.equalTo(bottomLineToCenterX)
                    make.width.equalTo(targetLabel.snp.width)
                        .offset(-self.style.bottomLineMargin)
                    make.top.equalTo(targetLabel.snp.bottom).offset(-self.bottomoffset)
                    make.height.equalTo(self.style.bottomLineH)
                })
                self.layoutIfNeeded()
            })
        }
    }
}

// MARK:- get the cgfloat of the color
extension ViewPageBar {
    
    fileprivate func rgb(_ color : UIColor) -> (CGFloat, CGFloat, CGFloat) {
        return (color.components[0] * 255, color.components[1] * 255, color.components[2] * 255)
    }
}
