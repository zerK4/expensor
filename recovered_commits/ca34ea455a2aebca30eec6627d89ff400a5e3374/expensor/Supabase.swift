//
//  Supabase.swift
//  expensor
//
//  Created by Sebastian Pavel on 18.05.2025.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://rkjxwslzporcoixnvptb.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJranh3c2x6cG9yY29peG52cHRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1Mzg4NDEsImV4cCI6MjA2MzExNDg0MX0.sz-GFI9Qfa_5BKwj6PFDbkNiajCkVhBsKj8sEn47iLI"
)
