# MyFinance - Architecture Overview

## App Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          MyFinance App                           │
│                      (Flutter Material App)                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Home Screen                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Total Savings│  │  Total Loans │  │Monthly Income│         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │    Loans     │  │   Savings    │  │   Payments   │         │
│  │    Button    │  │    Button    │  │    Button    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│  Loans Screen  │  │ Savings Screen │  │Payments Screen │
│                │  │                │  │                │
│ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │
│ │ Add Loan   │ │  │ │Add Savings │ │  │ │Add Payment │ │
│ └────────────┘ │  │ └────────────┘ │  │ └────────────┘ │
│                │  │                │  │                │
│ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │
│ │ View Loans │ │  │ │View Savings│ │  │ │View Payments│ │
│ └────────────┘ │  │ └────────────┘ │  │ └────────────┘ │
│                │  │                │  │                │
│ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌────────────┐ │
│ │Delete Loan │ │  │ │   Update   │ │  │ │Delete Pay  │ │
│ └────────────┘ │  │ │   Balance  │ │  │ └────────────┘ │
└────────────────┘  │ └────────────┘ │  │                │
                    │ ┌────────────┐ │  │ ┌────────────┐ │
                    │ │Delete Save │ │  │ │Filter Type │ │
                    │ └────────────┘ │  │ └────────────┘ │
                    └────────────────┘  └────────────────┘
                             │                   │
                             ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Data Service                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  getLoans() / saveLoans() / addLoan() / deleteLoan()    │  │
│  │  getSavings() / saveSavings() / addSavings() / etc.     │  │
│  │  getPayments() / savePayments() / addPayment() / etc.   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Shared Preferences                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Key: 'loans'     -> JSON Array of Loan objects         │  │
│  │  Key: 'savings'   -> JSON Array of Savings objects      │  │
│  │  Key: 'payments'  -> JSON Array of Payment objects      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Device Local Storage                          │
└─────────────────────────────────────────────────────────────────┘
```

## Data Models

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Loan       │    │     Savings     │    │     Payment     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ - id            │    │ - id            │    │ - id            │
│ - name          │    │ - name          │    │ - title         │
│ - amount        │    │ - balance       │    │ - amount        │
│ - interestRate  │    │ - targetAmount  │    │ - date          │
│ - startDate     │    │ - createdDate   │    │ - category      │
│ - endDate       │    │ - description   │    │ - description   │
│ - monthlyPayment│    │                 │    │ - type (enum)   │
│ - description   │    │ + progress%     │    │   * income      │
│                 │    │                 │    │   * expense     │
│ + toJson()      │    │ + toJson()      │    │ + toJson()      │
│ + fromJson()    │    │ + fromJson()    │    │ + fromJson()    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Data Flow

### Adding a New Item (e.g., Loan)

```
User Action (Tap Add Button)
        │
        ▼
Show Add Loan Dialog
        │
        ▼
User Fills Form & Taps Add
        │
        ▼
Form Validation
        │
        ▼
Create Loan Object
        │
        ▼
DataService.addLoan(loan)
        │
        ▼
Get Existing Loans from SharedPreferences
        │
        ▼
Add New Loan to List
        │
        ▼
Serialize List to JSON
        │
        ▼
Save JSON to SharedPreferences
        │
        ▼
Return to Loans Screen
        │
        ▼
Reload Data from DataService
        │
        ▼
Update UI with New List
```

### Viewing Data

```
Screen initState()
        │
        ▼
Call DataService.getLoans()
        │
        ▼
SharedPreferences.getString('loans')
        │
        ▼
Parse JSON String
        │
        ▼
Deserialize to List<Loan>
        │
        ▼
Return List to Screen
        │
        ▼
setState() with New Data
        │
        ▼
Build UI with Data
```

## Screen Navigation Flow

```
                    ┌─────────────────┐
                    │   Home Screen   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │  Loans   │   │ Savings  │   │ Payments │
       │  Screen  │   │  Screen  │   │  Screen  │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            │              │              │
       ┌────▼──────┐  ┌────▼──────┐  ┌────▼──────┐
       │ Add Loan  │  │Add Savings│  │Add Payment│
       │  Dialog   │  │  Dialog   │  │  Dialog   │
       └───────────┘  └────┬──────┘  └───────────┘
                           │
                      ┌────▼──────┐
                      │  Update   │
                      │  Balance  │
                      │  Dialog   │
                      └───────────┘

       Navigation: Push/Pop with MaterialPageRoute
       Data Refresh: After dialog closes with result
```

## Key Technologies

- **Framework**: Flutter (Dart)
- **UI**: Material Design 3
- **Storage**: shared_preferences package
- **Formatting**: intl package
- **State Management**: StatefulWidget with setState()
- **Navigation**: Navigator with push/pop

## Design Patterns Used

1. **Model-View-Service**: Clear separation of concerns
   - Models: Data structures
   - Views: UI screens and widgets
   - Services: Business logic and data persistence

2. **Factory Constructor**: For JSON deserialization
   - `Loan.fromJson()`
   - `Savings.fromJson()`
   - `Payment.fromJson()`

3. **Repository Pattern**: DataService acts as repository
   - Abstracts data storage details
   - Provides clean API for CRUD operations

4. **Singleton Service**: Single DataService instance per usage
   - Consistent data access
   - Simple instantiation in screens

## Color Scheme

```
Primary: Teal (Material 3 seed color)
Secondary: Based on Teal complementary colors

Semantic Colors:
- Green:  Savings, Income, Success
- Red:    Expenses, Delete, Negative
- Orange: Loans, Warning
- Blue:   Information, Progress
- Grey:   Neutral, Disabled, Background
```

## Widget Hierarchy (Home Screen Example)

```
MaterialApp
└── HomeScreen (Scaffold)
    ├── AppBar
    │   └── Text('My Finance')
    ├── Body (RefreshIndicator)
    │   └── ListView
    │       ├── SummaryCard (Total Savings)
    │       ├── SummaryCard (Total Loans)
    │       ├── SummaryCard (Monthly Income)
    │       ├── SummaryCard (Monthly Expenses)
    │       ├── QuickActions Section
    │       │   ├── ActionButton (Loans)
    │       │   ├── ActionButton (Savings)
    │       │   └── ActionButton (Payments)
    │       └── Recent Payments Section
    │           └── List of Payment Cards
    └── (No FloatingActionButton)
```

## Summary

The MyFinance app follows a clean, layered architecture with:
- **Presentation Layer**: Flutter screens and widgets
- **Business Logic Layer**: DataService for operations
- **Data Layer**: SharedPreferences for persistence

This architecture ensures:
- Easy maintenance and updates
- Clear separation of concerns
- Testable components
- Scalable structure for future enhancements