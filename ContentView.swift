//
//  ContentView.swift
//  Zoom
//
//  Created by Benjamin Who on 2/12/21.
//

import SwiftUI
import CoreData
import Foundation

// MARK: Content View Structure
struct ContentView: View {
    
    @State private var showWhatsNew = false
    // Get current Version of the App:
    @AppStorage("Onboarding View") var isShowingOnboardingScreen = true
    // Show onboarding view?
    @Environment(\.openURL) var openURL
    // Helper for URL
    @ObservedObject var notificationManager = LocalNotificationManager()
    @State var isPresented = false
    @State var isPresentingAddRepeatMeetingScreen = false
    // Boolean for Add Meeting Screen
    @Environment(\.managedObjectContext) private var viewContext
    // Using CoreData managed object
    func getCurrentAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let version = (appVersion as! String)
        return version
    }
    // Check if app if app has been started after update and trigger What's New screen if not
    func checkForUpdate() {
        let version = getCurrentAppVersion()
        let savedVersion = UserDefaults.standard.string(forKey: "savedVersion")
        if savedVersion == version {
            print("App is up to date!")
        } else {
            // Toggle to show WhatsNew Screen as Modal
            self.showWhatsNew.toggle()
            UserDefaults.standard.set(version, forKey: "savedVersion")
        }
    }
    
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.time, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    // Fetch Request return: One-Time Meetings
    @FetchRequest(
        entity: RepeatingItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RepeatingItem.repeats, ascending: true)],
        animation: .default)
    private var repeatingMeetings: FetchedResults<RepeatingItem>
    // Fetch Request return: Repeating Meetings

    // MARK: Content View Body
    var body: some View {
    // Checking if there are any meetings at all:
        if items.count == 0 && repeatingMeetings.count == 0 {
            NavigationView {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                            .frame(width: 40)
                        Text("You have no meetings. To add a meeting, click the +.")
                            .font(.body)
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                        Spacer()
                            .frame(width: 40)
                    }
                    Spacer()
                }
                .navigationTitle("My Meetings")
                .navigationBarItems(trailing:
                    Menu {
                        Button {
                            print("Create One-Time Meeting")
                            self.isPresented.toggle()
                        } label: {
                            Label("One-time", systemImage: "1.circle.fill")
                        }
                        Button {
                            print("Create repeating meeting")
                            self.isPresentingAddRepeatMeetingScreen.toggle()
                        } label: {
                            Label("Repeating", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    })
                    .navigationTitle("My Meetings")
                    .background(EmptyView()
                        .sheet(isPresented: $isPresented, content: {
                            AddANewMeeting(isPresented: self.$isPresented)
                        })
                    )
                    .background(EmptyView()
                        .sheet(isPresented: $showWhatsNew, content: {
                            WhatsNewView(showWhatsNew: self.$showWhatsNew)
                        })
                    )
                    .background(EmptyView()
                        .sheet(isPresented: $isShowingOnboardingScreen, content: { IntroductionView(isShowingIntroScreen: $isShowingOnboardingScreen)
                        })
                    )
                    .background(EmptyView()
                        .sheet(isPresented: $isPresentingAddRepeatMeetingScreen, content: {
                            AddRepeatMeeting(isPresentedRepeat: self.$isPresentingAddRepeatMeetingScreen)
                            })
                    )
                    .onAppear {
                        checkForUpdate()
                    }
                }
            // If there are meetings, show them in two sections
            
        } else {
            NavigationView {
                List {
                    Section(header:
                        Text("One-Time Meetings")
                            .textCase(nil)
                            .font(.headline)
                            .onAppear {
                                checkForUpdate()
                            }
                    ) {
                        ForEach(items, id: \.self) { item in
                            OneTimeRow(meeting: item)
                        }
                        .onDelete(perform: deleteItems, removeSingleNotification(meetingID: "Hello"))
                    }
                    Section(header:
                        Text("Repeating Meetings")
                            .font(.headline)
                            .textCase(nil)
                    ) {
                        ForEach(repeatingMeetings, id: \.self) { seconditem in
                            RepeatRow(meeting: seconditem)
                                .contextMenu {
                                    Button {
                                        print("User wants to see meeting information...navigating to detail view.")
                                    } label: {
                                        HStack {
                                            Image(systemName: "info.circle")
                                            Text("Meeting information")
                                        }
                                    }
                                    Button {
                                        print("Join meeting on iPhone")
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.up.forward")
                                            Text("Join meeting")
                                        }
                                    }
                                    Button {
                                        print("Share meeting")
                                    } label: {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Share meeting")
                                        }
                                    }
                                    Button {
                                        print("User wants to delete meeting")
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                                .foregroundColor(Color.red)
                                            Text("Delete meeting")
                                        }
                                    }
                                }
                        }
                        .onDelete(perform: deleteRepeats)
                    }
                }
                .listStyle(SidebarListStyle())
                .navigationBarItems(
                    leading: EditButton(),
                    trailing:
                        Menu {
                            Button {
                                print("first option")
                                self.isPresented.toggle()
                            } label: {
                                Label("One-time", systemImage: "1.circle.fill")
                            }
                            Button {
                                print("second option")
                                self.isPresentingAddRepeatMeetingScreen.toggle()
                            } label: {
                                Label("Repeating", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                        })
                .navigationTitle("My Meetings")
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
                .background(EmptyView()
                .sheet(isPresented: $isShowingOnboardingScreen, content: {
                    IntroductionView(isShowingIntroScreen: self.$isShowingOnboardingScreen)
                }))
                .onAppear {
                    checkForUpdate()
                }
                .background(EmptyView()
                    .sheet(isPresented: $showWhatsNew, content: {
                        WhatsNewView(showWhatsNew: $showWhatsNew)
                    })
                )
                .sheet(isPresented: $isPresented, content: {
                    AddANewMeeting(isPresented: $isPresented)
                })
                .background(EmptyView()
                    .sheet(isPresented: $isPresentingAddRepeatMeetingScreen, content: {
                        AddRepeatMeeting(isPresentedRepeat: self.$isPresentingAddRepeatMeetingScreen)
                    })
                )
            }
        }
    }
    // MARK: Functions
    private func deleteItems(offsets: IndexSet) {
        
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                
                try viewContext.save()
            } catch {
                print("There was an error deleting items")
            }
        }
    }
    
    private func removeSingleNotification(meetingID: String) {
        notificationManager.removePendingNotificationRequests(meetingID: meetingID)
        print("Deleted notification scheduled for meeting with identifier \(meetingID)")
    }
    
    private func deleteRepeats(offsets: IndexSet) {
        withAnimation {
            offsets.map { repeatingMeetings[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("There was an error deleting items")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

// MARK: Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
