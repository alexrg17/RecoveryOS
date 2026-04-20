//
//  SupabaseManager.swift
//  RecoveryOS
//
//  Created by Richy James on 20/04/2026.
//

import Supabase
import Foundation

// Shared Supabase client — import this file anywhere auth or DB calls are needed
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://znxtibteinoybxumoiej.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpueHRpYnRlaW5veWJ4dW1vaWVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2OTgwOTQsImV4cCI6MjA5MjI3NDA5NH0.UkGKe5M5OXQeB-whds9KC6Cvuklam6hDlSnCcaI2lVE"
)
