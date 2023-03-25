import { FC } from "react";
import { Props } from "./Props";

export const Layout: FC<Props> = (props) => {
    return (
        <>
            <nav> 
                <ul className="nav-links">
                    <li className="nav-item"><a href="#"><h2>ajdt</h2></a></li>
                    <li className="nav-item"><a href="#">Home</a></li>
                    <li className="nav-item"><a href="#">Timeline</a></li>
                </ul>
            </nav>
            {props.children}
        </>
    )
};