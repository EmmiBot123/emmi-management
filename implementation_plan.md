# Add Hardware Complaint and Delhivery Integration to Support Tickets

This plan outlines the changes needed to allow admins to mark a support ticket as a "Hardware Complaint" and deeply integrate with Delhivery for tracking and shipment creation.

## User Review Required
> [!IMPORTANT]
> **Delhivery API Key and Architecture**
> To integrate Delhivery directly into the app, we need a **Delhivery API Token**. 
> 
> *Security Note:* Making API calls to Delhivery directly from the Flutter app exposes the API Token in the app's code. Since this is an admin application, it might be acceptable, but typically this is handled by your backend. 
> 
> **Question 1:** Do you want the app to make direct API calls to Delhivery (I will need you to provide the API token later), or do you want the app to call your Render backend, which then talks to Delhivery?
> 
> **Question 2:** Do you want the app to *Create a Shipment* automatically when "Hardware Complaint" is checked, or do you just want to *Track* an existing shipment by entering a Waybill (AWB) number?

> [!WARNING]
> **API Schema Confirmation**
> We still need to persist the `isHardwareComplaint` and the `waybill` (AWB) number. The app will send these as fields to `https://edu-ai-backend-vl7s.onrender.com/support/tickets/:id`. 
> Please ensure the backend is set up to accept and store these fields.

## Proposed Changes

### Model

#### [MODIFY] `lib/Model/Support/support_ticket_model.dart`
- Add `bool isHardwareComplaint` field.
- Add `String? awbNumber` (Waybill Number) field.
- Update `fromJson` and `toJson` methods to parse and serialize these new fields.

### Repository

#### [MODIFY] `lib/Repository/Support/support_repository.dart`
- Add a new method `updateTicketHardwareDetails(String ticketId, bool isHardwareComplaint, String awbNumber)` to send a `PATCH` request to your backend.
- *(Optional depending on your answer)* Add a `DelhiveryRepository` class to handle calls to the Delhivery Track API (`https://track.delhivery.com/api/v1/packages/json/`) and fetch live shipment status.

### UI

#### [MODIFY] `lib/Screens/Support/support_ticket_list_page.dart`
- **Hardware Toggle:** Add a "Hardware Complaint" switch.
- **Waybill Input:** If the toggle is ON, display a `TextField` for the "Delhivery AWB Number".
- **Live Tracking UI:** If an AWB Number is saved, make a call to the Delhivery Track API and display the live tracking status (e.g., "In Transit", "Dispatched", "Delivered") and the latest scan location directly within the ticket card!

## Verification Plan

### Manual Verification
- Launch the application and navigate to Support Tickets.
- Mark a ticket as a Hardware Complaint and input a valid Delhivery AWB Number.
- Save the details.
- Verify that the app calls the Delhivery API and displays the correct, live tracking timeline and current status.
