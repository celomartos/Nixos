hl.env("AQ_NO_KMS_REQUIREMENT", "1")
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")

hl.monitor({
	output = "HEADLESS-1",
	mode = "1600x900@60",
	position = "0x0",
	scale = 1,
})

hl.exec_cmd("kitty")
