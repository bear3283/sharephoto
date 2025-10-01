//
//  LocalizedString.swift
//  SharingOnlyProject
//
//  Created by Claude on 9/30/25.
//

import Foundation

/// Type-safe localization helper for the app
/// Usage: LocalizedString.button_next or LocalizedString.General.appName
enum LocalizedString {

    // MARK: - General
    enum General {
        static let appName = "app_name".localized
        static let back = "general_back".localized
        static let next = "general_next".localized
        static let cancel = "general_cancel".localized
        static let confirm = "general_confirm".localized
        static let delete = "general_delete".localized
        static let close = "general_close".localized
        static let share = "general_share".localized
        static let add = "general_add".localized
        static let loading = "general_loading".localized
    }

    // MARK: - Sharing Steps
    enum Steps {
        static let dateSelection = "step_date_selection".localized
        static let recipientSetup = "step_recipient_setup".localized
        static let photoDistribution = "step_photo_distribution".localized
        static let albumPreview = "step_album_preview".localized

        static let dateSelectionSubtitle = "step_date_selection_subtitle".localized
        static let recipientSetupSubtitle = "step_recipient_setup_subtitle".localized
        static let photoDistributionSubtitle = "step_photo_distribution_subtitle".localized
        static let albumPreviewSubtitle = "step_album_preview_subtitle".localized
    }

    // MARK: - Directions
    enum Direction {
        static let top = "direction_top".localized
        static let bottom = "direction_bottom".localized
        static let left = "direction_left".localized
        static let right = "direction_right".localized
        static let topLeft = "direction_top_left".localized
        static let topRight = "direction_top_right".localized
        static let bottomLeft = "direction_bottom_left".localized
        static let bottomRight = "direction_bottom_right".localized
        static let directionSuffix = "direction_suffix".localized // " direction" in English
    }

    // MARK: - Photo View
    enum Photo {
        static let checking = "photo_checking".localized
        static let noPhotos = "photo_no_photos".localized
        static let noPhotosMessage = "photo_no_photos_message".localized
        static let noAddedPhotos = "photo_no_added_photos".localized
        static let noAddedPhotosMessage = "photo_no_added_photos_message".localized
        static let highQualityLoading = "photo_high_quality_loading".localized
        static let dummy = "photo_dummy".localized
    }

    // MARK: - Recipients
    enum Recipient {
        static let title = "recipient_title".localized
        static let maxCount = "recipient_max_count".localized
        static let addPerson = "recipient_add_person".localized
        static let addPersonMessage = "recipient_add_person_message".localized
        static let newRecipient = "recipient_new".localized
        static let enterName = "recipient_enter_name".localized
        static let selectDirection = "recipient_select_direction".localized
        static let noDirectionsAvailable = "recipient_no_directions_available".localized
        static let removeTitle = "recipient_remove_title".localized
        static let removeMessage = "recipient_remove_message".localized
        static let count = "recipient_count".localized // "%d people"
    }

    // MARK: - Photo Distribution
    enum Distribution {
        static let dragToDistribute = "distribution_drag_to_distribute".localized
        static let noRecipients = "distribution_no_recipients".localized
        static let noRecipientsMessage = "distribution_no_recipients_message".localized
        static let goToRecipientSetup = "distribution_go_to_recipient_setup".localized
        static let allPeople = "distribution_all_people".localized
        static let noRecipientStatus = "distribution_no_recipient_status".localized
        static let startDistribution = "distribution_start".localized
    }

    // MARK: - Album
    enum Album {
        static let temporaryAlbum = "album_temporary".localized
        static let photosDistributed = "album_photos_distributed".localized // "%d photos distributed"
        static let shareReady = "album_share_ready".localized
        static let someReady = "album_some_ready".localized
        static let photoCount = "album_photo_count".localized // "%d photos • %d/%d recipients"
        static let noAlbums = "album_no_albums".localized
        static let noAlbumsMessage = "album_no_albums_message".localized
        static let shareAll = "album_share_all".localized
        static let sharing = "album_sharing".localized
        static let addPhotos = "album_add_photos".localized
        static let addPhotosMessage = "album_add_photos_message".localized
        static let notFound = "album_not_found".localized
        static let photoCountText = "album_photo_count_text".localized // "%d photos"
        static let empty = "album_empty".localized
        static let emptyMessage = "album_empty_message".localized
        static let shareSuccess = "album_share_success".localized
        static let shareSuccessMessage = "album_share_success_message".localized
        static let loading = "album_loading".localized
    }

    // MARK: - Buttons
    enum Button {
        static let previous = "button_previous".localized
        static let next = "button_next".localized
        static let startDistribution = "button_start_distribution".localized
        static let checkAlbums = "button_check_albums".localized
        static let done = "button_done".localized
        static let startOver = "button_start_over".localized
        static let backToDistribution = "button_back_to_distribution".localized
        static let shareAlbum = "button_share_album".localized
    }

    // MARK: - Status
    enum Status {
        static let checking = "status_checking".localized
        static let noPhotos = "status_no_photos".localized
        static let noRecipients = "status_no_recipients".localized
        static let recipientsSet = "status_recipients_set".localized // "%d people set"
        static let recipientSetupNeeded = "status_recipient_setup_needed".localized
        static let dragToDistribute = "status_drag_to_distribute".localized
        static let photosCompleted = "status_photos_completed".localized // "%d photos completed"
        static let ready = "status_ready".localized
        static let distributionNeeded = "status_distribution_needed".localized
    }

    // MARK: - Alerts
    enum Alert {
        static let deletePhoto = "alert_delete_photo".localized
        static let deletePhotoMessage = "alert_delete_photo_message".localized
        static let deleteAllPhotos = "alert_delete_all_photos".localized
        static let deleteAllPhotosMessage = "alert_delete_all_photos_message".localized
        static let deleteAllAction = "alert_delete_all_action".localized
        static let removeFromAlbum = "alert_remove_from_album".localized
        static let removeFromAlbumMessage = "alert_remove_from_album_message".localized
        static let shareStatus = "alert_share_status".localized
    }

    // MARK: - Accessibility
    enum Accessibility {
        static let selectDate = "accessibility_select_date".localized
        static let selectDateHint = "accessibility_select_date_hint".localized
        static let deleteAllPhotos = "accessibility_delete_all_photos".localized
        static let deleteAllPhotosHint = "accessibility_delete_all_photos_hint".localized
        static let showAddedPhotos = "accessibility_show_added_photos".localized
        static let showAllPhotos = "accessibility_show_all_photos".localized
        static let toggleFilterHint = "accessibility_toggle_filter_hint".localized
        static let addPhoto = "accessibility_add_photo".localized
        static let addPhotoHint = "accessibility_add_photo_hint".localized
    }

    // MARK: - Empty States
    enum EmptyState {
        static let noPhotosTitle = "empty_state_no_photos_title".localized
        static let noPhotosSubtitle = "empty_state_no_photos_subtitle".localized
        static let noAddedPhotosTitle = "empty_state_no_added_photos_title".localized
        static let noAddedPhotosSubtitle = "empty_state_no_added_photos_subtitle".localized
    }
}

// MARK: - String Extension
private extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - Helper Functions for Formatted Strings
extension LocalizedString {
    /// Returns formatted string for photo count (e.g., "5 photos")
    static func photoCount(_ count: Int) -> String {
        return String(format: NSLocalizedString("album_photo_count_text", comment: ""), count)
    }

    /// Returns formatted string for recipient count (e.g., "3 people")
    static func recipientCount(_ count: Int) -> String {
        return String(format: NSLocalizedString("recipient_count", comment: ""), count)
    }

    /// Returns formatted string for status recipients (e.g., "3 people set")
    static func statusRecipientsSet(_ count: Int) -> String {
        return String(format: NSLocalizedString("status_recipients_set", comment: ""), count)
    }

    /// Returns formatted string for photos completed (e.g., "15 photos completed")
    static func statusPhotosCompleted(_ count: Int) -> String {
        return String(format: NSLocalizedString("status_photos_completed", comment: ""), count)
    }

    /// Returns formatted string for photos distributed (e.g., "20 photos distributed")
    static func photosDistributed(_ count: Int) -> String {
        return String(format: NSLocalizedString("album_photos_distributed", comment: ""), count)
    }

    /// Returns formatted string for album photo count with recipients (e.g., "25 photos • 5/8 recipients")
    static func albumPhotoCount(_ photoCount: Int, _ recipientCount: Int, _ totalRecipients: Int) -> String {
        return String(format: NSLocalizedString("album_photo_count", comment: ""), photoCount, recipientCount, totalRecipients)
    }
}