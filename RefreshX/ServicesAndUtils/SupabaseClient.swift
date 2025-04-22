//
//  SupabaseClient.swift
//  RefreshX



import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ilnpsjaucxmgixhxevah.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsbnBzamF1Y3htZ2l4aHhldmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NTEsImV4cCI6MjA2MDI3Njk1MX0.7B0cIhqMTXil_2el3paP9YNgRUW5e_Ik0oRVBeMTM2E"
)
