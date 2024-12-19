//
//  SessionDetailView.swift
//  Tetra
//
//  Created by yugoatobe on 12/5/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    
    let room: (
        title: String,
        memberNum: Int,
        location: String,
        image: String,
        description: String
    )
    
    
    var body: some View {
        HStack {
            PersonaCameraView()
                .frame(width: 400, height: 400)
                .background(Color.black)
                .cornerRadius(10)
                .padding()
            
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                // Title and Description
                VStack(alignment: .leading, spacing: 10) {
                    Text(room.title)
                        .font(.title)
                        .bold()
                    Text("By Morinosuke")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(room.description)
                        .font(.body)

                }
                .padding(.horizontal)

                
                // Buttons
                HStack(spacing: 20) {
                    let newFaceTimeLink = "https://facetime.apple.com/join#v=1&p=ZwAt7KeXEe+n9Y4xRDecvg&k=zyPbaG1l2PV4HUrjZFLUDoL0zQBUTwnPB2svFjYJToQ"
                    
                    Button(action: {
                        if let url = URL(string: newFaceTimeLink) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Join Chat")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Favourite action
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Favourite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                // Admin Section
                VStack(alignment: .leading, spacing: 5) {
                    Text("Admin")
                        .font(.callout)
                    HStack(spacing: 10) {
                        MemberView(name: "Liam", color: .pink)
                    }
                }
                .padding(.horizontal)

                // Members Section
                VStack(alignment: .leading, spacing: 5) {
                    Text("Member")
                        .font(.callout)
                    Text(String(room.memberNum))
                    VStack(alignment: .leading, spacing: 10) {
                        MemberView(name: "Ava", color: .yellow)
                        MemberView(name: "Mom", color: .orange)
                        MemberView(name: "Miley", color: .purple)
                        MemberView(name: "Ryan", color: .red)
                        MemberView(name: "Emily", color: .gray)
                    }
                    Text(room.location)
                        .font(.headline)
                }
                .padding(.horizontal)
                
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.trailing, 100)
            .frame(maxWidth: 500)
        }
    }
}

struct MemberView: View {
    var name: String
    var color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
            Text(name)
                .font(.headline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
