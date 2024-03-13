//
//  EditVaultView.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-12.
//

import SwiftUI

struct EditVaultView: View {
    let vault: Vault
    
    @State var showVaultExporter = false
    @State var showAlert = false
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        exporter
    }
    
    var base: some View {
        ZStack {
            background
            view
        }
    }
    
    var navigation: some View {
        base
            .navigationBarBackButtonHidden(true)
            .navigationTitle(NSLocalizedString("editVault", comment: "Edit Vault View title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationBackButton()
                }
            }
    }
    
    var alert: some View {
        navigation
            .alert(NSLocalizedString("deleteVaultTitle", comment: ""), isPresented: $showAlert) {
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) { delete() }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("deleteVaultDescription", comment: ""))
            }
    }
    
    var exporter: some View {
        alert
            .fileExporter(isPresented: $showVaultExporter, document: VoltixDocument(vault: vault), contentType: .data, defaultFilename: "\(vault.name).dat") { result in
                switch result {
                    case .failure(let error):
                        print("Fail to export, error: \(error.localizedDescription)")
                    case .success(let url):
                        print("Exported to \(url)")
                }
            }
    }
    
    var background: some View {
        Color.backgroundBlue
            .ignoresSafeArea()
    }
    
    var view: some View {
        ScrollView {
            VStack(spacing: 16) {
                backupVault
                editVault
                deleteVault
            }
        }
    }
    
    var backupVault: some View {
        Button {
            showVaultExporter = true
        } label: {
            EditVaultCell(title: "backup", description: "backupVault", icon: "arrow.down.circle.fill")
        }
        .padding(.top, 30)
    }
    
    var editVault: some View {
        EditVaultCell(title: "rename", description: "renameVault", icon: "square.and.pencil")
    }
    
    var deleteVault: some View {
        Button {
            showDeleteAlert()
        } label: {
            EditVaultCell(title: "delete", description: "deleteVault", icon: "trash.fill", isDestructive: true)
        }
    }
    
    private func showDeleteAlert() {
        showAlert.toggle()
    }
    
    private func delete() {
        modelContext.delete(vault)
        
        do {
            try modelContext.save()
        } catch {
            print("Error: \(error)")
        }
    }
}

#Preview {
    EditVaultView(vault: Vault.example)
}
