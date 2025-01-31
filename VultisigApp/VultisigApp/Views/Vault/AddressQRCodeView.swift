//
//  AddressQRCodeView.swift
//  VultisigApp
//
//  Created by Amol Kumar on 2024-03-08.
//

import SwiftUI

struct AddressQRCodeView: View {
    let addressData: String
    @Binding var showSheet: Bool
    @Binding var isLoading: Bool
    
    let padding: CGFloat = 30
    
    @State var qrCodeImage: Image? = nil
    @StateObject var shareSheetViewModel = ShareSheetViewModel()
    
    @Environment(\.displayScale) var displayScale
    
    var body: some View {
        ZStack {
            Background()
            view
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .navigationBarBackButtonHidden(true)
        .navigationTitle(NSLocalizedString("address", comment: "AddressQRCodeView title"))
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: Placement.topBarLeading.getPlacement()) {
                NavigationBackSheetButton(showSheet: $showSheet)
            }
#elseif os(macOS)
            ToolbarItem(placement: Placement.topBarLeading.getPlacement()) {
                NavigationBackButton()
            }
#endif
            
            ToolbarItem(placement: Placement.topBarTrailing.getPlacement()) {
                NavigationQRShareButton(title: "joinKeygen", renderedImage: shareSheetViewModel.renderedImage)
            }
        }

    }
    
    var view: some View {
        VStack(spacing: 50) {
            address
            qrCode
            Spacer()
        }
        .padding(.top, 30)
        .onAppear {
            setData()
        }
    }
    
    var address: some View {
        Text(addressData)
            .font(.body12Menlo)
            .foregroundColor(.neutral0)
            .multilineTextAlignment(.center)
            .padding(.horizontal, padding)
    }
    
    var qrCode: some View {
        GeometryReader { geometry in
            qrCodeImage?
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(24)
#if os(iOS)
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.width-(2*padding))
#elseif os(macOS)
                .frame(maxHeight: .infinity)
                .frame(width: geometry.size.height)
#endif
                .background(Color.turquoise600.opacity(0.15))
                .cornerRadius(10)
                .overlay (
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.turquoise600, style: StrokeStyle(lineWidth: 2, dash: [56]))
                )
                .padding(.horizontal, padding)
#if os(macOS)
                .frame(maxWidth: .infinity, alignment: .center)
#endif
        }
    }
    
    private func setData() {
        isLoading = false
        qrCodeImage = Utils.getQrImage(
            data: addressData.data(using: .utf8), size: 100)
        
        guard let qrCodeImage else {
            return
        }
        
        shareSheetViewModel.render(
            title: addressData,
            qrCodeImage: qrCodeImage,
            displayScale: displayScale
        )
    }
}

#Preview {
    AddressQRCodeView(addressData: "", showSheet: .constant(true), isLoading: .constant(false))
}
