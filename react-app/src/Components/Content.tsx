import { FC } from "react";
import { Props } from "./Props";
import { IntroductionSection } from "./IntroductionSection";
import { TimelineSection } from "./TimelineSection";
import { DownloadCVSection } from "./DownloadCVSection";

export const Content: FC<Props> = (props) => {
    return (
        <div className="content">
            <IntroductionSection />
            <TimelineSection />
            <DownloadCVSection />
        </div>
    )
};