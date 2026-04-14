# U-Share System - Comprehensive Test Cases

**System Name:** U-Share (Resource Lending System)  
**Version:** 1.0  
**Date:** April 2026  
**Platform:** Flutter Mobile App (iOS/Android)  
**Backend:** Firebase (Auth, Firestore, Messaging, Storage)

---

## Table of Contents
1. [System Overview](#system-overview)
2. [User Registration & Authentication](#user-registration--authentication)
3. [User Profile & Verification](#user-profile--verification)
4. [Item Management](#item-management)
5. [Request System](#request-system)
6. [Chat & Communication](#chat--communication)
7. [Rating & Review System](#rating--review-system)
8. [Transaction Management](#transaction-management)
9. [Notification System](#notification-system)
10. [Edge Cases & Error Handling](#edge-cases--error-handling)
11. [Performance & Load Testing](#performance--load-testing)

---

## System Overview

U-Share is a peer-to-peer resource lending platform for students. Users can:
- **Lenders**: Post items for borrowing and accept/decline requests
- **Borrowers**: Request items from other students and provide feedback
- **Both**: Rate each other, communicate via chat, manage transactions

### Key Features:
- Item posting with categories, timelines, and descriptions
- Request-based borrowing system with status tracking
- Real-time chat between lenders and borrowers
- User rating system (as lender and borrower)
- Identity verification for trust and safety
- Transaction time tracking with optional end dates
- Push notifications for requests and messages

---

## 1. User Registration & Authentication

### Test Case 1.1: Successful User Registration
**Objective:** Verify that a new user can successfully create an account

**Preconditions:**
- App is launched
- User is on the landing/login page

**Steps:**
1. Tap "Sign Up" button
2. Enter valid email (e.g., `student@university.edu`)
3. Enter password (min 6 characters, meets Firebase requirements)
4. Enter full name (e.g., "John Doe")
5. Tap "Create Account"

**Expected Result:**
- User account is created in Firebase Auth
- User document created in Firestore with:
  - `uid`: generated user ID
  - `email`: entered email
  - `fullName`: entered name
  - `createdAt`: server timestamp
  - `isVerified`: false
  - `verificationStatus`: "pending"
  - `hasSeenTutorial`: false
- User is redirected to basic information page
- Success message displayed

**Test Data:**
| Field | Value |
|-------|-------|
| Email | `test_student_1@university.edu` |
| Password | `SecurePass123!` |
| Full Name | `Alice Johnson` |

---

### Test Case 1.2: Registration - Weak Password
**Objective:** Verify system rejects weak passwords

**Steps:**
1. On sign-up page
2. Enter email: `user@university.edu`
3. Enter password: `123` (too short)
4. Enter name: `Test User`
5. Tap "Create Account"

**Expected Result:**
- Error message: "The password is too weak"
- Account not created
- User remains on sign-up page

---

### Test Case 1.3: Registration - Email Already Exists
**Objective:** Verify system prevents duplicate email registration

**Preconditions:**
- Email `existing@university.edu` already has an account

**Steps:**
1. On sign-up page
2. Enter email: `existing@university.edu`
3. Enter password: `ValidPass123`
4. Enter name: `Duplicate User`
5. Tap "Create Account"

**Expected Result:**
- Error message: "An account already exists with this email"
- Account not created
- User remains on sign-up page

---

### Test Case 1.4: Registration - Invalid Email Format
**Objective:** Verify system validates email format

**Steps:**
1. On sign-up page
2. Enter email: `invalid.email@` (incomplete)
3. Enter password: `ValidPass123`
4. Enter name: `Test User`
5. Tap "Create Account"

**Expected Result:**
- Error message: "Invalid email address"
- Account not created

---

### Test Case 1.5: Successful User Login
**Objective:** Verify existing user can login successfully

**Preconditions:**
- User account exists: email `existing@university.edu`, password `ValidPass123`

**Steps:**
1. On login page
2. Enter email: `existing@university.edu`
3. Enter password: `ValidPass123`
4. Tap "Login"

**Expected Result:**
- User is authenticated
- User is navigated to home/main navigation page
- Session is established

---

### Test Case 1.6: Login - Incorrect Password
**Objective:** Verify system rejects incorrect password

**Steps:**
1. On login page
2. Enter email: `existing@university.edu`
3. Enter password: `WrongPassword123`
4. Tap "Login"

**Expected Result:**
- Error message displayed
- Login fails
- User remains on login page

---

### Test Case 1.7: Login - Non-existent Email
**Objective:** Verify system handles non-existent account

**Steps:**
1. On login page
2. Enter email: `nonexistent@university.edu`
3. Enter password: `SomePassword123`
4. Tap "Login"

**Expected Result:**
- Error message: "User not found" or similar
- Login fails

---

### Test Case 1.8: Session Persistence
**Objective:** Verify user session persists after app restart

**Steps:**
1. Login successfully with user credentials
2. Navigate to home page
3. Close app completely
4. Restart app

**Expected Result:**
- User is automatically authenticated
- Home page is displayed
- No need to re-login

---

### Test Case 1.9: Logout
**Objective:** Verify user can logout successfully

**Steps:**
1. Logged-in user navigates to profile/settings
2. Tap "Logout" button

**Expected Result:**
- Session is terminated
- User is redirected to login/landing page
- No user cached data remains

---

## 2. User Profile & Verification

### Test Case 2.1: Complete Basic Information
**Objective:** Verify user can complete basic profile information

**Preconditions:**
- User is newly registered
- User is on "Basic Information" page

**Steps:**
1. Enter School ID: `STU123456`
2. Select Course: `Computer Science`
3. Select Section: `A`
4. Tap "Next"

**Expected Result:**
- Firestore user document updated with:
  - `schoolId`: `STU123456`
  - `course`: `Computer Science`
  - `section`: `A`
  - `profileCompleted`: true
- User navigated to next onboarding step

**Test Data:**
| Field | Value |
|-------|-------|
| School ID | `STU123456` |
| Course | `Computer Science` |
| Section | `A` |

---

### Test Case 2.2: Skip Verification (Tutorial)
**Objective:** Verify user can proceed with tutorial without immediate verification

**Steps:**
1. User completes basic information
2. On verification page, tap "Skip for Now" or similar
3. Proceed through tutorial pages

**Expected Result:**
- User marked as `hasSeenTutorial`: true
- User navigated to home page
- Verification status remains "pending"

---

### Test Case 2.3: Upload ID for Verification - Valid Documents
**Objective:** Verify user can upload identity documents for verification

**Preconditions:**
- User is on identity verification page
- Valid ID images exist on device

**Steps:**
1. Tap "Upload Front ID"
2. Select valid front ID image from gallery
3. Tap "Upload Back ID"
4. Select valid back ID image from gallery
5. Select verification type: "Government ID" or "Student ID"
6. Tap "Submit for Verification"

**Expected Result:**
- Images uploaded to Firebase Storage
- Firestore user document updated with:
  - `frontIdPath`: storage path
  - `backIdPath`: storage path
  - `verificationType`: selected type
  - `verificationSubmittedAt`: server timestamp
  - `verificationStatus`: "pending" (awaiting admin review)
- Success message displayed
- User navigated to "Verification In Progress" page

---

### Test Case 2.4: Verification Status - Approved
**Objective:** Verify user receives approval notification

**Preconditions:**
- User submitted verification documents
- Admin/System approved verification

**Steps:**
1. User checks app notification or navigates to profile
2. Verification status updated to "approved"

**Expected Result:**
- `verificationStatus` changed to "approved"
- `isVerified` set to true
- User sees "Verified" badge on profile
- User can now fully use lending features

---

### Test Case 2.5: Verification Status - Rejected
**Objective:** Verify user receives rejection with feedback

**Preconditions:**
- Admin/System rejected verification

**Steps:**
1. User checks app notification or profile
2. Verification status updated to "rejected"

**Expected Result:**
- `verificationStatus` changed to "rejected"
- User sees rejection message with reason (if provided)
- Option to resubmit documents provided

---

### Test Case 2.6: Edit Profile Information
**Objective:** Verify user can update profile details

**Steps:**
1. Logged-in user navigates to Profile Settings
2. Edit School ID to: `STU789012`
3. Change Course to: `Information Technology`
4. Change Section to: `B`
5. Tap "Save"

**Expected Result:**
- Firestore document updated with new values
- Changes reflected immediately in app
- Success notification displayed

---

### Test Case 2.7: View User Profile (Self)
**Objective:** Verify user can view their own profile

**Steps:**
1. Navigate to Profile page
2. View profile information

**Expected Result:**
Displays:
- Full name
- School/Verification info
- Rating as Lender (if available)
- Rating as Borrower (if available)
- Number of items listed
- Verification badge
- Items listed by user

---

### Test Case 2.8: View Other User Profile
**Objective:** Verify user can view another user's public profile

**Preconditions:**
- Viewing from item details or request page

**Steps:**
1. Tap on another user's name/profile
2. View their profile

**Expected Result:**
Displays:
- User's full name
- Verification status (if verified)
- Lender rating
- Borrower rating
- Number of listings
- Some items available for borrowing (not edit options)
- No personal information (email, school ID)

---

## 3. Item Management

### Test Case 3.1: Post New Item - All Fields Valid
**Objective:** Verify user can successfully post a new item

**Preconditions:**
- User is logged in
- User is on "Post Item" page
- User profile is completed

**Steps:**
1. Enter Item Name: `Mathematics Textbook`
2. Select Category: `Books`
3. Enter Description: `Advanced Calculus, barely used, includes notes`
4. Select Timeline: `1 Month`
5. Tap "Take Photo" or "Upload from Gallery"
6. Select/take valid image
7. Tap "Post Item"

**Expected Result:**
- Item created in Firestore with:
  - `itemName`: `Mathematics Textbook`
  - `category`: `Books`
  - `description`: description text
  - `timeline`: `1 Month`
  - `imageUrl`: uploaded image path
  - `ownerId`: current user ID
  - `ownerName`: current user name
  - `status`: "available"
  - `isActive`: true
  - `createdAt`: server timestamp
  - `borrowCount`: 0
- Success message: "Item posted successfully"
- User navigated to home page or item details

**Test Data:**
| Field | Value |
|-------|-------|
| Item Name | `Mathematics Textbook` |
| Category | `Books` |
| Description | `Advanced Calculus, barely used, includes notes` |
| Timeline | `1 Month` |
| Image | Valid JPG/PNG |

---

### Test Case 3.2: Post Item - Missing Required Fields
**Objective:** Verify system validates all required fields

**Steps:**
1. Enter Item Name: `Laptop`
2. Leave Category empty
3. Enter Description: `Gaming laptop`
4. Select Timeline: `2 Weeks`
5. Tap "Post Item"

**Expected Result:**
- Validation error: "Category is required"
- Item not posted
- Focus moved to Category field

---

### Test Case 3.3: Post Item - Invalid Image
**Objective:** Verify system validates image quality and size

**Steps:**
1. Fill all fields correctly
2. Attempt to upload corrupted/oversized image (>10MB)
3. Tap "Post Item"

**Expected Result:**
- Error message: "Image too large" or "Invalid image format"
- Item not posted

---

### Test Case 3.4: View All Available Items (Home Page)
**Objective:** Verify user can browse available items

**Steps:**
1. Navigate to Home page
2. View items in list/grid

**Expected Result:**
Displays:
- Item name
- Category
- Owner name
- Item image
- Timeline
- Items sorted appropriately (by recent/relevance)
- Only items with `status: "available"` shown
- Only items with `isActive: true` shown

---

### Test Case 3.5: Filter Items by Category
**Objective:** Verify user can filter items by category

**Preconditions:**
- Multiple items exist in different categories

**Steps:**
1. On Home page, tap Category filter
2. Select category: `Electronics`
3. View results

**Expected Result:**
- Only items with `category: "Electronics"` displayed
- Query: `where('isActive', isEqualTo: true).where('status', isEqualTo: 'available').where('category', isEqualTo: 'Electronics')`

---

### Test Case 3.6: View Item Details
**Objective:** Verify user can view complete item information

**Steps:**
1. From home page, tap on an item
2. View item details page

**Expected Result:**
Displays:
- Item image
- Item name
- Item description
- Category
- Timeline
- Owner name (clickable to profile)
- Owner verification badge
- Owner's lender rating
- "Request to Borrow" button (if not owner)
- Item status

---

### Test Case 3.7: Edit Posted Item
**Objective:** Verify owner can edit item details

**Preconditions:**
- User is logged in
- Item was posted by this user
- Item status is "available"

**Steps:**
1. Navigate to user's posted items
2. Tap Edit on specific item
3. Change description to: `Lightly used, some highlights`
4. Save changes

**Expected Result:**
- Firestore document updated
- Change reflected in item details
- `updatedAt` timestamp updated
- Other users see updated info

---

### Test Case 3.8: Remove/Delete Item
**Objective:** Verify owner can remove their item listing

**Steps:**
1. Navigate to user's items
2. Tap Delete on item
3. Confirm deletion

**Expected Result:**
- `isActive` set to false
- Item no longer appears in search/browse
- Firestore shows soft delete (not hard delete)

---

### Test Case 3.9: Item Status - Available to Borrowed
**Objective:** Verify item status updates when borrowed

**Preconditions:**
- Item exists with `status: "available"`
- Request for this item is accepted

**Steps:**
1. Item request is accepted by owner
2. Check item details

**Expected Result:**
- Item status changed to `"borrowed"`
- Item not available for new requests
- Borrowing user can be viewed on item

---

### Test Case 3.10: Item Status - Borrowed to Available
**Objective:** Verify item can become available again after return

**Preconditions:**
- Item status is "borrowed"
- Transaction/borrowing period ends

**Steps:**
1. Owner marks item as returned
2. Check item status

**Expected Result:**
- Item status changed back to `"available"`
- Item appears in available items again

---

## 4. Request System

### Test Case 4.1: Create New Request (Borrower)
**Objective:** Verify borrower can request to borrow an item

**Preconditions:**
- Borrower is logged in
- Item exists and is available
- Borrower is not the owner

**Steps:**
1. View available item details
2. Tap "Request to Borrow"
3. Tap "Confirm Request"

**Expected Result:**
- Request created in Firestore with:
  - `itemId`: item's ID
  - `itemName`: item name
  - `ownerId`: original owner's ID
  - `ownerName`: owner's name
  - `borrowerId`: borrower's ID
  - `borrowerName`: borrower's name
  - `status`: "pending"
  - `createdAt`: server timestamp
- Success message: "Request sent successfully"
- Request visible in borrower's "Outgoing Requests"

**Test Data:**
| Field | Value |
|-------|-------|
| Item | Mathematics Textbook |
| Borrower | Bob Smith |
| Owner | Alice Johnson |

---

### Test Case 4.2: Request - Cannot Request Own Item
**Objective:** Verify user cannot request their own item

**Preconditions:**
- User viewing their own posted item

**Steps:**
1. Navigate to own item details
2. Check for "Request to Borrow" button

**Expected Result:**
- "Request to Borrow" button not visible
- Button replaced with "Edit Item" or similar

---

### Test Case 4.3: View Incoming Requests (Lender Mode)
**Objective:** Verify item owner can see pending requests

**Preconditions:**
- Requests exist for user's items

**Steps:**
1. Navigate to Requests page
2. Switch to "Lender Mode" (if applicable)
3. View incoming requests

**Expected Result:**
Displays requests with:
- Item name
- Borrower name
- Request date
- Request status (PENDING RESPONSE)
- Action buttons: "Accept" / "Decline"

Query: `where('ownerId', isEqualTo: userId).where('status', isEqualTo: 'pending')`

---

### Test Case 4.4: Accept Request (Lender)
**Objective:** Verify lender can accept a borrowing request

**Preconditions:**
- Pending request visible

**Steps:**
1. On Lender mode, view request
2. Tap "Accept" button
3. (Optional) Set return date
4. Confirm acceptance

**Expected Result:**
- Request status changed to `"accepted"`
- Item status changed to `"borrowed"`
- Borrower notified (push notification)
- Chat room automatically created
- Request appears in "Accepted Requests"
- User can tap "Start Chat" to message borrower

---

### Test Case 4.5: Decline Request (Lender)
**Objective:** Verify lender can decline a request

**Steps:**
1. On Lender mode, view request
2. Tap "Decline" button

**Expected Result:**
- Request status changed to `"declined"`
- Item remains available for other requests
- Borrower notified of decline
- Request removed from lender's pending list

---

### Test Case 4.6: View Outgoing Requests (Borrower Mode)
**Objective:** Verify borrower can see their requests

**Preconditions:**
- User has made borrowing requests

**Steps:**
1. Navigate to Requests page
2. Switch to "Borrower Mode"
3. View outgoing requests

**Expected Result:**
Displays requests with:
- Item name
- Lender name
- Request date
- Request status (PENDING RESPONSE, ACCEPTED, DECLINED)
- Status badge colors:
  - Yellow: PENDING RESPONSE
  - Green: ACCEPTED
  - Red: DECLINED
- Conditional buttons:
  - "Cancel" (if pending)
  - "Start Chat" (if accepted)

---

### Test Case 4.7: Cancel Own Request (Borrower)
**Objective:** Verify borrower can cancel pending request

**Steps:**
1. In Borrower mode, find pending request
2. Tap "Cancel" button
3. Confirm cancellation

**Expected Result:**
- Request status changed to `"cancelled"`
- Item available for other requests
- Lender notified of cancellation
- Request removed from borrower's pending list

---

### Test Case 4.8: Request Status - Accepted Badge
**Objective:** Verify accepted requests show correct status

**Preconditions:**
- Request is accepted

**Steps:**
1. View request in list

**Expected Result:**
- Status badge shows "ACCEPTED" in green
- "Start Chat" button visible

---

### Test Case 4.9: Request with Transaction End Date
**Objective:** Verify system tracks return deadline

**Preconditions:**
- Lender accepts request and sets return date

**Steps:**
1. Lender accepts request
2. Sets return date to: `2026-05-07`
3. Confirm

**Expected Result:**
- `transactionEndDate` stored as Timestamp: `2026-05-07`
- Chat room updated with this date
- Reminder notifications sent before deadline
- Item marked for return

---

### Test Case 4.10: Request - Duplicate Prevention
**Objective:** Verify user cannot make multiple requests for same item

**Preconditions:**
- Pending request exists for this item

**Steps:**
1. Attempt to create another request for same item
2. Tap "Request to Borrow"

**Expected Result:**
- Error message: "You already have a pending request for this item"
- New request not created

---

## 5. Chat & Communication

### Test Case 5.1: Auto-Create Chat Room
**Objective:** Verify chat room created when request accepted

**Preconditions:**
- Lender accepts a request

**Steps:**
1. Lender accepts request
2. Borrower navigates to Chat

**Expected Result:**
- Chat room automatically created in Firestore:
  - `participants`: [borrowerId, ownerId]
  - `itemId`: item ID
  - `itemName`: item name
  - `requestId`: request ID
  - `status`: "active"
  - `createdAt`: timestamp
- Chat room visible to both parties

---

### Test Case 5.2: Send Message
**Objective:** Verify users can send messages in chat

**Preconditions:**
- Chat room exists between two users
- Both users have accepted notification permissions

**Steps:**
1. Open chat room
2. Type message: `When can you pick it up?`
3. Tap Send button

**Expected Result:**
- Message created in Firestore:
  - `senderId`: sender ID
  - `senderName`: sender name
  - `message`: message text
  - `timestamp`: server timestamp
  - `read`: false
- Message appears in chat UI immediately
- Recipient receives push notification (if not in app)

---

### Test Case 5.3: Real-Time Message Sync
**Objective:** Verify messages sync in real-time

**Preconditions:**
- Chat room open on both devices

**Steps:**
1. Send message from Device A
2. Check Device B

**Expected Result:**
- Message appears on Device B within 1-2 seconds
- No app restart needed
- Uses Firestore realtime listeners

---

### Test Case 5.4: Mark Messages as Read
**Objective:** Verify read status updates

**Steps:**
1. Recipient views received message

**Expected Result:**
- Message `read` field updated to true
- Sender can see message was read

---

### Test Case 5.5: View Message History
**Objective:** Verify chat history persists

**Steps:**
1. Close chat room
2. Reopen chat room

**Expected Result:**
- All previous messages appear in order
- Messages sorted by timestamp (ascending)
- No messages lost

---

### Test Case 5.6: Send Image in Chat
**Objective:** Verify users can share images via chat

**Preconditions:**
- Chat room open

**Steps:**
1. Tap image/attachment icon
2. Select image from gallery
3. Send

**Expected Result:**
- Image uploaded to Firebase Storage
- Image URL/reference stored in message
- Image appears in chat
- Recipient can view/download image

---

### Test Case 5.7: Chat Notifications While App Closed
**Objective:** Verify user receives notifications for messages

**Preconditions:**
- User has enabled notifications
- App is closed/in background

**Steps:**
1. Participant sends message
2. Observe notification

**Expected Result:**
- Push notification received on lock screen
- Notification shows sender name and message preview
- Tapping notification opens chat room

---

### Test Case 5.8: Chat Notifications While App Open
**Objective:** Verify in-app message handling

**Preconditions:**
- App is open
- User in chat room

**Steps:**
1. Participant sends message
2. Observe app behavior

**Expected Result:**
- Message appears immediately in chat UI
- No duplicate notification if already viewing

---

### Test Case 5.9: Chat Room with Transaction Info
**Objective:** Verify chat displays transaction details

**Preconditions:**
- Chat room for accepted request

**Steps:**
1. Open chat room
2. View header/details

**Expected Result:**
Displays:
- Other user's name and avatar
- Item name (clickable link to item)
- Return/transaction end date (if set)
- Status

---

### Test Case 5.10: End Chat/Transaction
**Objective:** Verify chat can be marked as completed

**Preconditions:**
- Item returned/transaction complete

**Steps:**
1. Owner or borrower marks transaction as complete
2. Chat status updated

**Expected Result:**
- Chat room `status` changed to `"transaction_ended"`
- Messaging still available but marked as history
- Rating dialog prompted to rate other user

---

## 6. Rating & Review System

### Test Case 6.1: Submit Lender Rating
**Objective:** Verify borrower can rate lender (item owner)

**Preconditions:**
- User is a borrower in completed transaction
- Item has been returned
- Rating dialog displayed

**Steps:**
1. Rating dialog appears
2. Select rating: 4.5 stars
3. Enter feedback: `Very smooth transaction, item was as described`
4. Tap "Submit Rating"

**Expected Result:**
- Rating stored in Firestore at:
  - `users/{lenderId}/ratings/lender`
- Rating data includes:
  - `averageRating`: calculated average
  - `totalRatings`: count
  - `reviews`: array with new review:
    - `rating`: 4.5
    - `feedback`: text
    - `raterName`: borrower name
    - `transactionId`: transaction ID
    - `timestamp`: server timestamp
- Success message displayed

**Test Data:**
| Field | Value |
|-------|-------|
| Rating | 4.5 stars |
| Feedback | `Very smooth transaction, item was as described` |

---

### Test Case 6.2: Submit Borrower Rating
**Objective:** Verify lender can rate borrower

**Preconditions:**
- User is lender in completed transaction

**Steps:**
1. Rating dialog appears
2. Select rating: 5 stars
3. Enter feedback: `Took great care of the item, returned on time`
4. Tap "Submit Rating"

**Expected Result:**
- Rating stored in Firestore at:
  - `users/{borrowerId}/ratings/borrower`
- Same structure as lender rating

---

### Test Case 6.3: View Lender Rating (Self)
**Objective:** Verify user can see their own lender rating

**Steps:**
1. Navigate to Profile
2. View Lender Rating section

**Expected Result:**
Displays:
- Average rating (e.g., 4.7 out of 5)
- Total number of ratings
- List of recent reviews with:
  - Star rating
  - Feedback text
  - Rater name
  - Date
- No duplicates (one rating per transaction)

---

### Test Case 6.4: View Borrower Rating (Self)
**Objective:** Verify user can see their own borrower rating

**Steps:**
1. Navigate to Profile
2. View Borrower Rating section

**Expected Result:**
Same structure as lender rating

---

### Test Case 6.5: Rating - Prevent Duplicate
**Objective:** Verify user cannot rate same transaction twice

**Preconditions:**
- User already submitted rating for this transaction

**Steps:**
1. Attempt to submit another rating for same transaction
2. Tap "Submit Rating"

**Expected Result:**
- Error: "You have already rated this transaction"
- Rating not submitted
- Original rating unchanged

---

### Test Case 6.6: View Other User's Ratings
**Objective:** Verify public rating display on other profiles

**Steps:**
1. View another user's profile

**Expected Result:**
Displays:
- Lender rating badge (if exists) with count
- Borrower rating badge (if exists) with count
- Top/recent reviews from both categories
- Note: Full detailed reviews only visible to that user

---

### Test Case 6.7: Rating Calculation
**Objective:** Verify average rating calculated correctly

**Preconditions:**
- User has multiple ratings

**Test Data:**
| Rating 1 | Rating 2 | Rating 3 | Expected Average |
|----------|----------|----------|------------------|
| 5.0 | 4.0 | 3.0 | 4.0 |
| 5.0 | 5.0 | 5.0 | 5.0 |
| 1.0 | 5.0 | 3.0 | 3.0 |

**Expected Result:**
- Average correctly calculated
- Displayed with one decimal place

---

### Test Case 6.8: Rating Impact on Trust
**Objective:** Verify high ratings increase user trust signal

**Steps:**
1. User with high ratings (4.5+) posts new item
2. Other users browse items

**Expected Result:**
- Verified badge + high rating visible
- Item ranks higher in search (potential future feature)
- More request for items from trusted users

---

## 7. Transaction Management

### Test Case 7.1: Track Transaction Timeline
**Objective:** Verify system tracks transaction from request to return

**Preconditions:**
- Item being borrowed

**Timeline:**
1. Request sent: `2026-04-07 10:00 AM`
2. Request accepted: `2026-04-07 10:05 AM`
3. Item picked up: `2026-04-07 02:00 PM`
4. Item returned: `2026-04-20 03:00 PM`

**Expected Result:**
- Firestore stores all timestamps
- Chat history shows transaction progress
- Notifications sent at key points
- Duration tracked

---

### Test Case 7.2: Transaction End Date Approach
**Objective:** Verify reminders when return date approaching

**Preconditions:**
- Transaction has end date: `2026-04-20`
- Current date: `2026-04-18`

**Steps:**
1. Check notifications

**Expected Result:**
- Reminder notification: "Item due back in 2 days"
- Borrower receives reminder

---

### Test Case 7.3: Overdue Item
**Objective:** Verify system tracks overdue items

**Preconditions:**
- Transaction end date: `2026-04-15`
- Current date: `2026-04-22`

**Steps:**
1. Check item status

**Expected Result:**
- Flag item as overdue
- Send notification to borrower
- Lender notified of delay
- Track days overdue

---

### Test Case 7.4: Item Return Confirmation
**Objective:** Verify owner can confirm item return

**Preconditions:**
- Item is borrowed
- Borrower indicates return

**Steps:**
1. Lender/Owner receives return notification
2. Confirms item received
3. Marks transaction complete

**Expected Result:**
- Item status reverted to `"available"`
- Transaction marked as complete
- Rating prompt appears

---

### Test Case 7.5: Transaction History
**Objective:** Verify users can view past transactions

**Steps:**
1. Navigate to Profile > Transaction History
2. View past borrowings/lendings

**Expected Result:**
Displays:
- Item name
- Other party name
- Borrow dates
- Return date
- Status (completed, cancelled, overdue)
- Rating given/received

---

## 8. Notification System

### Test Case 8.1: Request Notification (Lender)
**Objective:** Verify owner notified when request received

**Preconditions:**
- User enabled notifications
- User is item owner

**Steps:**
1. Borrower sends request for user's item

**Expected Result:**
- Push notification received:
  - Title: `New Borrow Request`
  - Body: `{BorrowerName} wants to borrow {ItemName}`
- Notification delivered within 2 seconds
- Tapping opens Requests page

---

### Test Case 8.2: Request Accepted Notification (Borrower)
**Objective:** Verify borrower notified when request accepted

**Preconditions:**
- Borrower made request

**Steps:**
1. Lender accepts request

**Expected Result:**
- Push notification:
  - Title: `Request Accepted`
  - Body: `{LenderName} accepted your request for {ItemName}`
- Tapping opens chat with lender

---

### Test Case 8.3: Request Declined Notification (Borrower)
**Objective:** Verify borrower notified of decline

**Steps:**
1. Lender declines request

**Expected Result:**
- Notification: `{LenderName} declined your request`

---

### Test Case 8.4: Message Notifications
**Objective:** Verify users notified of new messages

**Preconditions:**
- User has disabled/background app

**Steps:**
1. Participant sends message

**Expected Result:**
- Notification with sender name and message preview
- Delivered even if app closed

---

### Test Case 8.5: FCM Token Storage
**Objective:** Verify user device tokens stored for messaging

**Preconditions:**
- Chat initialized

**Steps:**
1. System obtains FCM token
2. Stores in user document

**Expected Result:**
- `users/{userId}/fcmToken` populated
- Token persists for future notifications

---

### Test Case 8.6: Notification Permission Prompt
**Objective:** Verify system requests notification permission

**Preconditions:**
- Fresh install or permissions cleared

**Steps:**
1. App started
2. Chat initialized

**Expected Result:**
- iOS/Android permission dialog
- Options: Allow / Don't Allow
- If allowed: notifications enabled
- If denied: notifications disabled (can be changed in settings)

---

### Test Case 8.7: Disable Notifications
**Objective:** Verify user can turn off notifications

**Steps:**
1. Navigate to Settings/Profile
2. Toggle "Notifications" OFF
3. System action triggers

**Expected Result:**
- Notifications disabled
- No push notifications received
- Setting persisted

---

## 9. Edge Cases & Error Handling

### Test Case 9.1: Network Disconnect - Request Creation
**Objective:** Verify handled gracefully

**Preconditions:**
- User creating request
- Network goes down

**Steps:**
1. Start request creation
2. Network unavailable
3. Tap Submit

**Expected Result:**
- Error message: "No internet connection"
- Data cached for retry when online
- No duplicate request created

---

### Test Case 9.2: Firebase Auth Token Expiry
**Objective:** Verify token refresh

**Preconditions:**
- User logged in for extended time

**Steps:**
1. Wait for token expiry
2. Perform action requiring auth

**Expected Result:**
- Token automatically refreshed
- Action completes
- User unaware of background refresh

---

### Test Case 9.3: Firestore Quota Exceeded
**Objective:** Verify system handles rate limiting

**Preconditions:**
- High traffic/rapid requests

**Steps:**
1. Multiple rapid requests
2. Quota exceeded

**Expected Result:**
- User-friendly error message
- Retry button offered
- No data corruption

---

### Test Case 9.4: Missing User Profile Data
**Objective:** Verify graceful handling of incomplete profiles

**Preconditions:**
- User has missing profile fields

**Steps:**
1. Another user views profile

**Expected Result:**
- Missing fields show placeholder
- App doesn't crash
- "Unknown" or "--" displayed for missing data

---

### Test Case 9.5: Concurrent Request - Same Item
**Objective:** Verify system handles race condition

**Preconditions:**
- User A and B both request same item simultaneously

**Steps:**
1. Signal both to send request at same time

**Expected Result:**
- Both requests created
- First accepted takes item (becomes borrowed)
- Second request stays pending
- No conflicts in database

---

### Test Case 9.6: Delete Account with Active Requests
**Objective:** Verify cascade handling

**Preconditions:**
- User has pending requests/active transactions

**Steps:**
1. User deletes account
2. Check system state

**Expected Result:**
- User document marked as deleted
- Requests automatically declined
- Active borrowers notified
- Items hidden from search

---

### Test Case 9.7: Image Upload Failure
**Objective:** Verify graceful failure handling

**Preconditions:**
- Firebase Storage unavailable

**Steps:**
1. Attempt to upload image
2. Upload fails

**Expected Result:**
- Error message: "Failed to upload image. Please try again."
- Item creation blocked until successful
- Item data not saved without image

---

### Test Case 9.8: Chat History Large Data
**Objective:** Verify performance with many messages

**Preconditions:**
- Chat room has 500+ messages

**Steps:**
1. Open chat room
2. Scroll through history
3. Send new message

**Expected Result:**
- Chat loads in <2 seconds
- Scrolling smooth (paginate/load on scroll)
- New messages sent without delay

---

### Test Case 9.9: Rating - Invalid Input
**Objective:** Verify rating validation

**Steps:**
1. Submit rating with empty feedback
2. Attempt rating > 5 stars

**Expected Result:**
- Validation error
- Alert shown
- Rating not submitted until valid

---

### Test Case 9.10: Firestore Security Rules Violation
**Objective:** Verify permission denied handled

**Preconditions:**
- Security rules updated
- User attempts unauthorized action

**Steps:**
1. User tries to edit another user's item
2. Firestore denies

**Expected Result:**
- Error: "Permission denied"
- User alerted
- Update not reflected

---

## 10. Performance & Load Testing

### Test Case 10.1: Home Page Load Time
**Objective:** Verify acceptable page load time

**Preconditions:**
- App opened fresh
- Network: 4G

**Steps:**
1. Navigate to Home
2. Measure time to display items

**Expected Result:**
- **Target**: < 2 seconds
- Items list displays
- Images load progressively

---

### Test Case 10.2: Search/Filter Performance
**Objective:** Verify filter queries execute quickly

**Preconditions:**
- 1000+ items in database

**Steps:**
1. Filter by category
2. Observe response time

**Expected Result:**
- Results displayed in < 1 second
- Uses efficient Firestore queries with indexes

---

### Test Case 10.3: Chat Room Performance
**Objective:** Verify smooth chat with many messages

**Preconditions:**
- Chat has 1000+ messages

**Steps:**
1. Open chat
2. Send message
3. Receive message

**Expected Result:**
- Message send: < 0.5 seconds
- Message receive: < 1 second
- UI remains responsive

---

### Test Case 10.4: Profile Load Time
**Objective:** Verify profile page performance

**Steps:**
1. Open user with 50+ ratings
2. Measure load time

**Expected Result:**
- Loads in < 2 seconds
- Ratings infinite scroll implemented
- No UI freeze

---

### Test Case 10.5: Push Notification Response
**Objective:** Verify timely notification delivery

**Preconditions:**
- Firebase Messaging configured

**Steps:**
1. Create request
2. Measure notification arrival

**Expected Result:**
- **Target**: Delivered within 2 seconds
- Handles thousands of concurrent sends

---

### Test Case 10.6: Memory Usage
**Objective:** Verify app doesn't leak memory

**Preconditions:**
- Monitor RAM usage

**Steps:**
1. Use app for 30 minutes
2. Navigate through multiple screens
3. Check memory

**Expected Result:**
- Memory stable
- No continuous increase
- < 200MB baseline usage

---

### Test Case 10.7: Battery Consumption
**Objective:** Verify efficient background processing

**Preconditions:**
- Chat running in background
- Notifications enabled

**Steps:**
1. App in background for 1 hour
2. Check battery drain

**Expected Result:**
- Normal background battery drain
- Efficient Firestore listeners
- Location services not used unnecessarily

---

## 11. Future/Planned Features

These features are not currently implemented but may be planned:

### Feature 11.1: Borrow Analytics Dashboard
**Planned Functionality:**
- View borrowing statistics
- Most borrowed items
- Borrowing trends
- User engagement metrics

### Feature 11.2: Advanced Search
**Planned Functionality:**
- Full-text search on item names/descriptions
- Distance-based search (near me)
- Price range filters
- Availability calendar

### Feature 11.3: Wishlist
**Planned Functionality:**
- Save favorite items for later
- Get alerts when similar items posted
- Share wishlist with others

### Feature 11.4: Item Condition Report
**Planned Functionality:**
- Before/after photos of returned items
- Condition rating system
- Damage documentation
- Insurance for damaged items

### Feature 11.5: Dispute Resolution
**Planned Functionality:**
- Report problematic transactions
- Admin mediation
- Refund/compensation handling
- Appeal process

### Feature 11.6: Subscription/Premium Features
**Planned Functionality:**
- Unlimited item listings
- Priority in recommendations
- Advanced analytics
- Premium support

### Feature 11.7: Social Features
**Planned Functionality:**
- Follow other users
- Post activity feed
- Community groups/clubs
- Events coordination

### Feature 11.8: Payment Integration
**Planned Functionality:**
- Optional insurance payments
- Damage compensation
- Premium feature payments
- Transaction fees (future monetization)

---

## Test Environment & Setup

### Device Testing
- **iOS**: iPhone 12 Pro (iOS 15+)
- **Android**: Samsung Galaxy S21 (Android 12+)
- **Tablets**: iPad (iOS), Samsung Tab (Android)

### Firebase Test Configuration
- **Firestore**: Test mode with security rules
- **Auth**: Email/password enabled
- **Storage**: 5GB limit for test images
- **Messaging**: FCM tokens tracked

### Test Data Setup
```
# Users for testing
User 1: alice@university.edu (Lender, Verified)
User 2: bob@university.edu (Borrower, Verified)
User 3: charlie@university.edu (Unverified)

# Test Items
Item 1: Mathematics Textbook (Books, Available)
Item 2: Gaming Laptop (Electronics, Available)
Item 3: Bicep Gym Equipment (Equipment, Available)

# Test Categories
- Books
- Electronics
- Equipment
- Clothing
- Notes & Documents
- Other
```

### Regression Testing Checklist
- [ ] Authentication flow still works
- [ ] Item posting/browsing functional
- [ ] Requests send/receive correctly
- [ ] Chat messages sync in real-time
- [ ] Ratings calculate properly
- [ ] Notifications delivery
- [ ] No data loss on app restart
- [ ] Security rules enforced
- [ ] Error messages user-friendly

---

## Known Issues / Blocked Tests
(To be updated as issues discovered)

| Issue | Status | Impact | Resolution |
|-------|--------|--------|-------------|
| [Example] Chat notifications in iOS | Open | Medium | Requires iOS 13+ for proper UNUserNotificationCenter |
| (To be updated) | | | |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Test Lead | | | |
| Developer | | | |
| QA Manager | | | |
| Client/PM | | | |

---

**Document Version**: 1.0  
**Last Updated**: April 7, 2026  
**Next Review**: May 7, 2026
